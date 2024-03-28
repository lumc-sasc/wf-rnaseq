//Subworkflows and processes/modules are loaded in.
include { QCwf }                                                from "../subworkflows/QC.nf"
include {BamMetricswf }                                         from "../subworkflows/BamMetrics.nf"
include { STAR_GENOMEGENERATE as Star_Genomegenerate}           from "../modules/star/genomegenerate/main.nf"
include { STAR_ALIGN as Star_Align}                             from "../modules/star/align/main.nf"
include {HISAT2_ALIGN as Hisat2_Align}                          from "../modules/hisat2/align/main.nf"
include {SAMTOOLS_SORT as Samtools_Sort}                        from "../modules/samtools/sort/main.nf" 
include {PICARD_MARKDUPLICATES as Picard_Markduplicates}        from "../custom_modules/picard/markduplicates/main.nf"
include {UMITOOLS_DEDUP as Dedup}                               from "../modules/umitools/dedup/main.nf"
include {PICARD_MARKDUPLICATES as Picard_Markduplicates_dedup}  from "../custom_modules/picard/markduplicates/main.nf"


//defines splicesites
splicesites = file("$baseDir/${params.splicesites}").exists() ? ${params.splicesites} : [[id: "refgtf"],[]]

//defines the star index
star_index = file("$baseDir/${params.starIndex}/SAindex").exists() ? ["${params.starIndex}/SAindex"] : null

//defines the hisat 2 index and seperates all index files from each other and creating seperate instances.
hisat2_index = Channel.fromList([file("$baseDir/inputfiles/${params.hisat2}/*.ht2")]).map {instance ->
            return [[id: "hisat"], instance]}.set {hisat2_indexChannel}


//Start of workflow
workflow Samplewf{
    //Input of workflow are given.
    take:
        read_list
        referenceFasta
        referenceFastaFai
        referenceFastaDict
        referenceGtfFile 
        refflatFile

    //Main part of workflow.
    main:
        //QC subworkflow is being run.
        QCwf(read_list)


        //It checks if star Index is present. If so, it will add all files of star_index and then Star_Index will run.
        if (star_index != null) {
            star_index << file("./inputfiles/${params.starIndex}/*")
            Star_Align(QCwf.out.reads, star_index , params.star_ignore_sjdbgtf, params.seq_platform, params.seq_center)
        }


        //If hisat2 file is present, it will run Hisat2_Align and then sorts the output using Samtools Sort
        if (file("./inputfiles/${params.hisat2}/*.ht2").size() > 0) {
            Hisat2_Align(QCwf.out.reads,hisat2_indexChannel, splicesites)
            Samtools_Sort(Hisat2_Align.out.bam)
        }


        /*If neither star file and hisat2 file are present, it will generate a star_index using the reference
        genome and then run Star Align using it.*/
        if (star_index == null && file("./inputfiles/${params.hisat2}/*.ht2").size() == 0) {
            Star_Genomegenerate(referenceFasta[0,1], referenceGtfFile)
            Star_Align(QCwf.out.reads,Star_Genomegenerate.out.index, referenceGtfFile, params.star_ignore_sjdbgtf,params.seq_platform,params.seq_center)
        }

        
        //combine all readgroups into samples.
        Align_output = params.starIndex != null ? Star_Align.out.bam : (file("./inputfiles/${params.hisat2}/*.ht2").size() > 0 ? Samtools_Sort.out.bam : Star_Align.out.bam)
        Align_output.map {instance ->
            identification = instance[0].sample
            single = instance[0].single_end
            reads = instance[1]
            return [[id:identification, single_end: single], reads]}.groupTuple().set{Markduplicates_input}

        //Run markduplicates and combine the output bam and bai in a single channel.
        Picard_Markduplicates(Markduplicates_input, fasta = [[id:'genome'],[]], fastaFai = [[id:'genome'],[]])
        duplicates_output = Picard_Markduplicates.out.bam.join(Picard_Markduplicates.out.bai)

        //checks if deduplication is true and is run if true.
        if (params.umiDeduplication) {
            Dedup(duplicates_output, params.get_output_stats)
            Picard_Markduplicates_dedup(Dedup.out.bam, fasta = [[id:'genome'],[]], fastafai = [[id:'genome'],[]])
            duplicates_dedup_output = Picard_Markduplicates_dedup.out.bam.join(Picard_Markduplicates_dedup.out.bai)
        }
        //BamMetrics subworkflow is being run.
        BamMetricswf(params.umiDeduplication ? duplicates_dedup_output : duplicates_output, referenceFasta, referenceFastaFai, referenceFastaDict, refflatFile)

        //alignment reports
        alignment_reports = star_index != null && file("./inputfiles/${params.hisat2}/*.ht2").size() > 0 ?
            [Star_Align.out.log_final, Hisat2_Align.out.summary] : star_index != null ?
            Star_Align.out.log_final : file("./inputfiles/${params.hisat2}/*.ht2").size() > 0 ? Hisat2_Align.out.summary :
            Star_Align.out.log_final

        //markduplicates reports
        markduplicates_report = params.umiDeduplication ?
            Picard_Markduplicates.out.metrics.join(Picard_Markduplicates_dedup.out.metrics) :
            Picard_Markduplicates.out.metrics

        //Changing the reports identifiction so it can be joined with the others

        //QC reports
        QCwf.out.reports.map { instance ->
            identification = "report"
            reports = instance.subList(1, instance.size())
            return [[id:identification], reports]}.groupTuple().set{QC_reports}

        //Bammetrics reports
        BamMetricswf.out.reports.map { instance ->
            reports = instance.subList(1, instance.size())
            return [[id:"report"], reports]}.groupTuple().set{BamMetrics_reports}

        //Alignment reports
        alignment_reports.map { instance ->
            reports = instance.subList(1,instance.size())
            return [[id:"report"], reports]}.groupTuple().set{alignment_report}

       
        //Markduplicates reports
        markduplicates_report.map { instance ->
            reports = instance.subList(1,instance.size())
            return [[id:"report"], reports]}.groupTuple().set{markduplicates_report}
        
        //UmiDeduplication reports
        if (params.umiDeduplication) {
            Dedup.out.log.map { instance ->
                reports = instance.subList(1,instance.size)
                return [[id:"report"], reports]}.groupTuple().set{Dedup_reports}
        }
        //End of changing the identification.
    
        //Report Channels are being merged. It will also check if umideduplication is true and add it if it is true.
        reports = QC_reports.join(BamMetrics_reports).join(alignment_report).join(markduplicates_report)
        reports = params.umiDeduplication ? reports.join(Dedup_reports) : reports

        //Removes all the unnecesary []
        reports.map{return [it[0], it.subList(1, it.size()).flatten()]}.set{reports}
        
    //Emit the output.
    emit:
        bam = params.umiDeduplication ? duplicates_dedup_output: duplicates_output
        reports = reports

}

