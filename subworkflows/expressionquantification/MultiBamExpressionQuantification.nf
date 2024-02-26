//All processes/modules are loaded in.
include {STRINGTIE_STRINGTIE as Stringtie} from "../../modules/stringtie/stringtie/main.nf"
include {GFFCOMPARE as Gff_Compare} from "../../modules/gffcompare/main.nf"
include {STRINGTIE_STRINGTIE as Stringtie_quan} from "../../modules/stringtie/stringtie/main.nf"
include {HTSEQ_COUNT as Htseq_Count} from "../../modules/htseq/count/main.nf"
include {COLLECT_COLUMN as Collect_Column_8} from "../../custom_modules/collect_column/main.nf"
include {COLLECT_COLUMN as Collect_Column_7} from "../../custom_modules/collect_column/main.nf"
include {CONVERTTEXTTOCSV as ConvertTextToCsv} from "../../custom_modules/convert_text_to_csv/main.nf"
include {COLLECT_COLUMN as Collect_Column_count} from "../../custom_modules/collect_column/main.nf"

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
    detectNovelTranscripts = file("inputfiles/${params.referenceGtfFile}").exists() ? false : true
    
    //checks if dtectnoveltranscripts is true
    if (detectNovelTranscripts || params.lncRNAdetection) {
        Stringtie(bam, referenceGtfFile[1])

        //Combines all samples of the Stringtie output together into a single list, which is then used in Gff Compare
        Stringtie.out.transcript_gtf.map {instance ->
        gtf = instance[1]
        return [[id:"combined"], gtf]}.groupTuple().set{Stringtie_output}

        Gff_Compare(Stringtie_output, referenceFasta << referenceFastaFai[1], referenceGtfFile)

    }

    /*looks if runstringtiequantification is true, if so it will run stringtie quantification. Besides it will
    also check if Gff_Compare has an annotated output. If neither is true, it will use the referencegtf as gtf.*/
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

    //If stringtie quantification is enabled, it will run stringtie quan.
    if (params.runStringtieQuantification){
        Stringtie_quan(bam, gtf)
    }

    //Htseq count
    Htseq_Count(bam, gtf_with_meta)

    //If stringtie quantification is enabled, it will run the collect collumn on collumn 8 and 7 from stringtie quan output.
    if (params.runStringtieQuantification){
        Collect_Column_8(Stringtie_quan.out.abundance, gtf_with_meta, valueColumn = 8)
        Collect_Column_7(Stringtie_quan.out.abundance, gtf_with_meta, valueColumn = 7)
    }
    /*Changing the output of Htseq count to report format. All samples will be merged together into a single list
    so it can be used for can be used for Collect column*/
    Htseq_Count.out.txt.map { instance ->
            identification = "report"
            reports = instance[1]
            return [identification, reports]}.groupTuple()
        .map{return [[id:it[0]], it[1].flatten()]}.set{Htseq_count_report}

    //Collect column count is being run using the reports from Htseq count.        
    Collect_Column_count(Htseq_count_report, gtf_with_meta, valueColumn = 000)

    //Change output of Colllect column so it can be joined with Htseq count.
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