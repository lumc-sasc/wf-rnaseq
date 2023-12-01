include {STRINGTIE_STRINGTIE as Stringtie} from "../../modules/stringtie/stringtie/main.nf"
include {GFFCOMPARE as Gff_Compare} from "../../modules/gffcompare/main.nf"
include {STRINGTIE_STRINGTIE as Stringtie_quan} from "../../modules/stringtie/stringtie/main.nf"
include {HTSEQ_COUNT as Htseq_Count} from "../../modules/htseq/count/main.nf"
include {COLLECT_COLUMN as Collect_Column_8} from "../../custom_modules/collect_column/main.nf"
include {COLLECT_COLUMN as Collect_Column_7} from "../../custom_modules/collect_column/main.nf"
include {CONVERTTEXTTOCSV as ConvertTextToCsv} from "../../custom_modules/convert_text_to_csv/main.nf"
include {COLLECT_COLUMN as Collect_Column_count} from "../../custom_modules/collect_column/main.nf"

workflow MultiBamExpressionQuantificationwf {
    take:
    bam
    referenceGtfFile
    referenceFasta
    referenceFastaFai

    main:
    detectNovelTranscripts = file("../../inputfiles/${params.referenceGtfFile}").exists() ? false : true
    
    //checks if dtectnoveltranscripts is true
    if (detectNovelTranscripts || params.lncRNAdetection) {
        Stringtie(bam, referenceGtfFile.map {it[1]})

        //reduce from sample to whole
        Stringtie.out.transcript_gtf.map {instance ->
        gtf = instance[1]
        return [[id:"combined"], gtf]}.groupTuple().set{Stringtie_output}

        Gff_Compare(Stringtie_output, referenceFasta << referenceFastaFai[1], referenceGtfFile)

    }

    //looks if runstringtiequantification is true, if so it will run stringtie quantification.
    if (params.runStringtieQuantification){
        gtf = detectNovelTranscripts ? Gff_Compare.out.annotated_gtf.map {it[1]} : referenceGtfFile.map {it[1]}
        Stringtie_quan(bam, gtf)
    }
    //Htseq count
    referenceGtf = detectNovelTranscripts ? Gff_Compare.out.annotated_gtf : referenceGtfFile
    Htseq_Count(bam, referenceGtf)

    if (params.runStringtieQuantification){
        Collect_Column_8(Stringtie_quan.out.abundance, referenceGtf, valueColumn = 8)
        Collect_Column_7(Stringtie_quan.out.abundance, referenceGtf, valueColumn = 7)
    }
    Collect_Column_count(Htseq_Count.out.txt, referenceGtf, valueColumn = 000)

    emit:
    gtf = params.lncRNAdetection ? Gff_Compare.out.annotated_gtf : ""

}