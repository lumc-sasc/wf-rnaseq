//Including modules
include { STAR_GENOMEGENERATE as Star_Genomegenerate} from "../../modules/star/genomegenerate/main.nf"
include { STAR_ALIGN as Star_Align} from "../../modules/star/align/main.nf"
include {HISAT2_ALIGN as Hisat2_Align} from "../../modules/hisat2/align/main.nf"
include {SAMTOOLS_SORT as Samtools_Sort} from "../../modules/samtools/sort/main.nf" 

def ALIGN(reads, referenceFasta) {

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


    //It checks if star Index is present. If so, it will add all files of star_index and then Star_Index will run.
    if (star_index != null) {
        star_index << file("./inputfiles/${params.starIndex}/*")

        Star_Align( reads,
                    star_index,
                    params.star_ignore_sjdbgtf,
                    params.seq_platform, 
                    params.seq_center)
    }


    //If hisat2 file is present, it will run Hisat2_Align and then sorts the output using Samtools Sort
    else if (file("./inputfiles/${params.hisat2}/*.ht2").size() > 0) {
        Hisat2_Align(   reads,
                        hisat2_indexChannel,
                        splicesites)

        Samtools_Sort(Hisat2_Align.out.bam)
    }


    /*If neither star file and hisat2 file are present, it will generate a star_index using the reference
    genome and then run Star Align using it.*/
    else {

        Star_Align( reads,
                    star_index = Star_Genomegenerate(referenceFasta).out.index, 
                    params.star_ignore_sjdbgtf, 
                    params.seq_platform, 
                    params.seq_center)
    }

    Align_output = params.starIndex != null ? Star_Align.out.bam : (file("./inputfiles/${params.hisat2}/*.ht2").size() > 0 ? Samtools_Sort.out.bam : Star_Align.out.bam)

    return Align_output
}