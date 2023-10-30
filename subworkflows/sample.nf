include { QCwf } from "../subworkflows/QC.nf"
include {BamMetricswf } from "../subworkflows/BamMetrics.nf"
include { STAR_GENOMEGENERATE as Star_Genomegenerate} from "../modules/star/genomegenerate/main.nf"
include { STAR_ALIGN as Star_Align} from "../modules/star/align/main.nf"
include { STAR_ALIGN as Star_Align_star} from "../modules/star/align/main.nf"
include {HISAT2_ALIGN as Hisat2_Align} from "../modules/hisat2/align/main.nf"
include {PICARD_MARKDUPLICATES as Picard_Markduplicates} from "../modules/picard/markduplicates/main.nf"
include {UMITOOLS_DEDUP as Dedup} from "../modules/umitools/dedup/main.nf"
include {PICARD_MARKDUPLICATES as Picard_Markduplicates_dedup} from "../modules/picard/markduplicates/main.nf"


//parameters for star
params.star_ignore_sjdbgtf = true
params.seq_platform = "illumina"
params.seq_center = false
params.umiDeduplication = false
params.get_output_stats = false


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
        
        //creation of bam files
        if (params.starIndex) {
            Star_Align_star(QCwf.out.reads,params.starIndex,params.star_ignore_sjdbgtf,params.seq_platform,params.seq_center)
            Picard_Markduplicates(Star_Align_star.out.bam, referenceFasta, referenceFastaFai)
        }
        else if (params.hisat2Index) {
            Hisat2_Align(QCwf.out.reads,params.hisat2Index)
            Picard_Markduplicates(Hisat2_Align.out.bam, referenceFasta, referenceFastaFai)
        }
        else {
            Star_Genomegenerate(referenceFasta)
            Star_Align(QCwf.out.reads,Star_Genomegenerate.out.index,params.star_ignore_sjdbgtf,params.seq_platform,params.seq_center)
            Picard_Markduplicates(Star_Align.out.bam, referenceFasta, referenceFastaFai)

        }
        if (params.umiDeduplication) {
            Dedup(Picard_Markduplicates.out.bam, params.get_output_stats)
            Picard_Markduplicates_dedup(Dedup.out.bam, referenceFasta, referenceFastaFai)
        }
        Dedup.out.bam.view()
        //BamMetrics
        if (params.umiDeduplication) {
            BamMetricswf(Picard_Markduplicates_dedup.out.bam, referenceFasta, referenceFastaFai, referenceFastaDict, refflatFile)
        }
        else {
            BamMetricswf(Picard_Markduplicates.out.bam, referenceFasta, referenceFastaFai, referenceFastaDict, refflatFile)
        }
    
    emit:
    bam = params.umiDeduplication ? Picard_Markduplicates_dedup.out.bam : Picard_Markduplicates.out.bam

}

