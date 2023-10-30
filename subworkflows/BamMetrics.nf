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
    Picard_Collectmultiplemetrics(bam_bai,referenceFasta,referenceFastaFai,referenceFastaDict)

    if (refflatFile != null) {
        Picard_Collectrnaseqmetrics(bam_bai, refflatFile, referenceFasta.map {it[1]}, [])
        
    }

}