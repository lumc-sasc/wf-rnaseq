include { QCwf } from "../subworkflows/QC.nf"
include {BamMetricswf } from "../subworkflows/BamMetrics.nf"
include { STAR_GENOMEGENERATE as Star_Genomegenerate} from "../modules/star/genomegenerate/main.nf"
include { STAR_ALIGN as Star_Align} from "../modules/star/align/main.nf"
include {HISAT2_ALIGN as Hisat2_Align} from "../modules/hisat2/align/main.nf"
include {SAMTOOLS_SORT as Samtools_Sort} from "../modules/samtools/sort/main.nf" 
include {PICARD_MARKDUPLICATES as Picard_Markduplicates} from "../modules/picard/markduplicates/main.nf"
include {UMITOOLS_DEDUP as Dedup} from "../modules/umitools/dedup/main.nf"
include {PICARD_MARKDUPLICATES as Picard_Markduplicates_dedup} from "../modules/picard/markduplicates/main.nf"


//defines splicesites
splicesites = file("./inputfiles/${params.splicesites}").exists() ?
            file("./inputfiles/${params.splicesites}") : 
            Channel.value([[id: "refgtf"],[]])

//defines the star index
star_index = file("./inputfiles/${params.starIndex}/SAindex").exists() ?
            [file("./inputfiles/${params.starIndex}/SAindex")] :
            null

//defines the hisat 2 index and seperates all index files from each other and creating seperate instances.
hisat2_index = Channel.fromList([file("./inputfiles/${params.hisat2}/*.ht2")])
hisat2_index.map {instance ->
            return [[id: "hisat"], instance]}.set {hisat2_indexChannel}

workflow samplewf{
    //input from the the other workflow
    take:
    read_list
    referenceFasta
    referenceFastaFai
    referenceFastaDict
    refflatFile
    
    main:
        QCwf(read_list)
        //if Star file is present
        if (star_index != null) {
            star_index << file("./inputfiles/${params.starIndex}/SA")
            star_index << file("./inputfiles/${params.starIndex}/genomeParameters.txt")
            star_index << file("./inputfiles/${params.starIndex}/Genome")
            star_index << file("./inputfiles/${params.starIndex}/chrStart.txt")
            star_index << file("./inputfiles/${params.starIndex}/chrNameLength.txt")
            star_index << file("./inputfiles/${params.starIndex}/chrName.txt")
            star_index << file("./inputfiles/${params.starIndex}/chrLenght.txt")


            Star_Align(QCwf.out.reads, star_index , params.star_ignore_sjdbgtf, params.seq_platform, params.seq_center)
        }
        //if hisat2 file is present
        if (file("./inputfiles/${params.hisat2}/*.ht2").size() > 0) {
            Hisat2_Align(QCwf.out.reads,hisat2_indexChannel, splicesites)
            Samtools_Sort(Hisat2_Align.out.bam)
        }

        //if neither star file and hisat2 file are present.
        if (star_index == null && file("./inputfiles/${params.hisat2}/*.ht2").size() == 0) {
            Star_Genomegenerate(referenceFasta)
            Star_Align(QCwf.out.reads,Star_Genomegenerate.out.index,params.star_ignore_sjdbgtf,params.seq_platform,params.seq_center)

        }
        //combine all readgroups into samples.
        Align_output = params.starIndex != null ? Star_Align.out.bam : (file("./inputfiles/${params.hisat2}/*.ht2").size() > 0 ? Samtools_Sort.out.bam : Star_Align.out.bam)
        Align_output.map {instance ->
            identification = instance[0].sample
            reads = instance[1]
            return [[id:identification], reads]}.groupTuple().set{Markduplicates_input}

        //markduplicates
        Picard_Markduplicates(Markduplicates_input, referenceFasta, referenceFastaFai)
        duplicates_output = Picard_Markduplicates.out.bam.join(Picard_Markduplicates.out.bai)

        //checks if deduplication is true and is run if true.
        if (params.umiDeduplication) {
            Dedup(duplicates_output, params.get_output_stats)
            Picard_Markduplicates_dedup(Dedup.out.bam, referenceFasta, referenceFastaFai)
            duplicates_dedup_output = Picard_Markduplicates_dedup.out.bam.join(Picard_Markduplicates_dedup.out.bai)
        }
        //BamMetrics
        BamMetricswf(params.umiDeduplication ? duplicates_dedup_output : duplicates_output, referenceFasta, referenceFastaFai, referenceFastaDict, refflatFile)

        //alignment reports
        alignment_reports = star_index != null && file("./inputfiles/${params.hisat2}/*.ht2").size() > 0 ?
            [Star_Align.out.log_final, Hisat2_Align.out.summary] : star_index != null ?
            Star_Align.out.log_final : file("./inputfiles/${params.hisat2}/*.ht2").size() > 0 ? Hisat2_Align.out.summary :
            Star_Align.out.log_final

        //markduplicates reports
        markduplicates_report = params.umiDeduplication ?
            [Picard_Markduplicates.out.metrics, Picard_Markduplicates_dedup.out.metrics] :
            Picard_Markduplicates.out.metrics
        
        dedup_report = params.umiDeduplication ? Dedup.out.log : null


    
    emit:
    bam = params.umiDeduplication ? duplicates_dedup_output: duplicates_output
    reports = [QCwf.out.reports, BamMetricswf.out.reports, alignment_reports, markduplicates_report, dedup_report]

}

