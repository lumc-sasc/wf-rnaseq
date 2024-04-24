//All the procecsses are included.
include {SAMTOOLS_FLAGSTAT as Samtools_Flagstat} from "../modules/nf-core/samtools/flagstat/main.nf"
include {PICARD_COLLECTMULTIPLEMETRICS as Picard_Collectmultiplemetrics} from "../modules/nf-core/picard/collectmultiplemetrics/main.nf"
include {PICARD_COLLECTRNASEQMETRICS as Picard_Collectrnaseqmetrics} from "../modules/nf-core/picard/collectrnaseqmetrics/main.nf"


//Start of workflow.
workflow BamMetricswf {

    //Grabs the input.
    take:
    bam_bai
    referenceFasta
    referenceFastaFai
    referenceFastaDict
    refflatFile

    //Main part of the workflow.
    main:

    //Count the number of alignment for each Flag type on the bam file.
    Samtools_Flagstat(bam_bai)

    //Collects multiple classes of the metrics.
    Picard_Collectmultiplemetrics(bam_bai,referenceFasta[0,1],referenceFastaFai)

    //It checks if the refflatFile exists. If it exists, it will run collectrnaseqmetrics
    if (refflatFile != null) {

        //Produces metrics describing the distributionof the bases within the transcripts.
        Picard_Collectrnaseqmetrics(bam_bai, refflatFile[1], referenceFasta[1], params.rrna_intervals)
        
    }

    //Combines outputfiles depending on if refflatFile is present or not. It will exclude collectrnaseqmetrics report if refflat is not present.
    reports = refflatFile != null ? Samtools_Flagstat.out.flagstat.join(Picard_Collectmultiplemetrics.out.metrics).
    join(Picard_Collectrnaseqmetrics.out.metrics) :
        Samtools_Flagstat.out.flagstat.join(Picard_Collectmultiplemetrics.out.metrics)

    //emits output.
    emit:
    reports = reports

}