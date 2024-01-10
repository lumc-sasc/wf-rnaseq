include {SAMTOOLS_FLAGSTAT as Samtools_Flagstat} from "../modules/samtools/flagstat/main.nf"
include {PICARD_COLLECTMULTIPLEMETRICS as Picard_Collectmultiplemetrics} from "../modules/picard/collectmultiplemetrics/main.nf"
include {PICARD_COLLECTRNASEQMETRICS as Picard_Collectrnaseqmetrics} from "../modules/picard/collectrnaseqmetrics/main.nf"


workflow BamMetricswf {
    take:
    bam_bai
    referenceFasta
    referenceFastaFai
    referenceFastaDict
    refflatFile


    main:
    Samtools_Flagstat(bam_bai)
    Picard_Collectmultiplemetrics(bam_bai,referenceFasta,referenceFastaFai)
    if (refflatFile != null) {
        Picard_Collectrnaseqmetrics(bam_bai, refflatFile, referenceFasta[1], params.rrna_intervals)
        
    }
    reports = refflatFile != null ? Samtools_Flagstat.out.flagstat.join(Picard_Collectmultiplemetrics.out.metrics).
    join(Picard_Collectrnaseqmetrics.out.metrics) :
        Samtools_Flagstat.out.flagstat.join(Picard_Collectmultiplemetrics.out.metrics)

    emit:
    reports = reports

}