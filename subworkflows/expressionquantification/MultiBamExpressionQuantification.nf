//All processes are loaded in.
include {STRINGTIE_STRINGTIE as Stringtie} from "../../modules/nf-core/stringtie/stringtie/main.nf"
include {GFFCOMPARE as Gff_Compare} from "../../modules/nf-core/gffcompare/main.nf"
include {STRINGTIE_STRINGTIE as Stringtie_quan} from "../../modules/nf-core/stringtie/stringtie/main.nf"
include {HTSEQ_COUNT as Htseq_Count} from "../../modules/nf-core/htseq/count/main.nf"
include {COLLECT_COLUMN as Collect_Column_8} from "../../modules/local/collect_column/main.nf"
include {COLLECT_COLUMN as Collect_Column_7} from "../../modules/local/collect_column/main.nf"
include {COLLECT_COLUMN as Collect_Column_count} from "../../modules/local/collect_column/main.nf"

//Start of workflow
workflow MultiBamExpressionQuantificationwf {
    //Input of workflow.
    take:
    bam
    referenceGtfFile
    referenceFasta
    referenceFastaFai

    //Main part of workflow.
    main:

    //It will check if the referenceGTF is present. If it is present, detectNovelTranscripts will be set to false, else it will be set to true.
    detectNovelTranscripts = file(params.genomes[ params.genome ][ 'referenceGTF' ]).exists() ? false : true
    
    //checks if dtectnoveltranscripts is true or if the lncRNAdetection is true. If either is true, it will run stringtie with Gff_Compare
    if (detectNovelTranscripts || params.lncRNAdetection) {

        //Runs stringtie with the bam and referenceGtfFile. referenceGtfFile is only give if detectNovelTranscripts is false and lncRNAdetection is true.
        Stringtie(bam, referenceGtfFile[1])

        //Combines all samples of the Stringtie output together into a single list, which is then used in Gff Compare
        Stringtie.out.transcript_gtf.map {instance ->
        gtf = instance[1]
        return [[id:"combined"], gtf]}.groupTuple().set{Stringtie_output}

        //runs the Gff_Compare with grouped output of stringtie, referencegenome, and referenceGtfFile if present.
        Gff_Compare(Stringtie_output, referenceFasta << referenceFastaFai[1], referenceGtfFile)

    }

    /* This conditional statement first looks if detectNovelTranscripts is true. This is because if it is true, 
    It won't use the referenceGtfFile when performing Gff_Compare, which means it uses the novel approach, which creates combined_gtf output rather than annotated.
    If detectNoveltranscripts is false but lncRNAdetection is true, it will run Gff_Compare, but in this case the stringite output will be annotated
    on the referenceGtfFile. If neither is true, it will use the referenceGtf as the gtf file.
    */
    if (detectNovelTranscripts) {
        gtf = Gff_Compare.out.combined_gtf.map {it[1]}.collect()
        gtf_with_meta = Gff_Compare.out.combined_gtf.collect()
        }
    else if (params.lncRNAdetection) {
        gtf = Gff_Compare.out.annotated_gtf.map {it[1]}.collect()
        gtf_with_meta = Gff_Compare.out.annotated_gtf.collect()
        }
    else {
        gtf = referenceGtfFile[1]
        gtf_with_meta = referenceGtfFile
    }

    //If stringtie quantification is enabled, it will align the bam with the referenceGtfFile (if present) and send the resulting report to the multiQC for viewing.
    if (params.runStringtieQuantification){

        //Runs stringtie and aligns the bam with the referenceGtfFile if present.
        Stringtie_quan(bam, gtf)

        //Grabs the report files from the stringtie process and groups all the instances together in a single list.
        Stringtie_quan.out.abundance.map {instance ->
                identification = "report"
                reports = instance[1]
                return [[id:identification],reports]}.groupTuple().set{collumn_input}
    }

    //Htseq count is executed to get the gene expression.
    Htseq_Count(bam, gtf_with_meta)

    //If stringtie quantification is enabled, it will run the collect collumn on collumn 8 and 7 from the stringtie report.
    if (params.runStringtieQuantification){
        Collect_Column_8(collumn_input, gtf_with_meta, valueColumn = 8, true, true)
        Collect_Column_7(collumn_input, gtf_with_meta, valueColumn = 7, true, true)
    }

    //Grabs the report files from the Htseq process and groups all of the instances together in a single list.
    Htseq_Count.out.txt.map { instance ->
            identification = "report"
            reports = instance[1]
            return [identification, reports]}.groupTuple()
        .map{return [[id:it[0]], it[1].flatten()]}.set{Htseq_count_report}

    //Collects all the counts together in a single file.   
    Collect_Column_count(Htseq_count_report, gtf_with_meta, valueColumn = 000, false, false)

    //Change output of Colllect column so it can be joined with Htseq count report.
    Collect_Column_count.out.csv.map { instance ->
            identification = "report"
            reports = instance
            return [[id:identification], reports]}.set{Collect_column_report}
    
    //combining the reports from Htseq_count and Collumn collect
    reports = Htseq_count_report.join(Collect_column_report)

    //reformat the reportchannel so the files are in a single list.
    reports.map {return [it[0], it[1,-1].flatten()]}.set{reports}

    //emitting the output of the workflow
    emit:
    gtf = gtf
    report = reports

}