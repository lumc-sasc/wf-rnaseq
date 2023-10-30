  nextflow.enable.dsl=2
   //testruncode ubuntu
   //nextflow run RNA-seq.nf --sampleConfigFile FunctionalPairedEnd.yml --referenceFasta reference.fasta --referenceFastaFai --reference.fasta.fai --referenceFastaDict reference.dict

    //include all processes and scripts
    include { samplewf } from "./subworkflows/sample.nf"
    include {Calculateregionswf} from "./subworkflows/Calculateregions.nf"
    import org.yaml.snakeyaml.Yaml
    
    
    
//"input output defining"    
//"-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"    
    // Base filepath will be defined in here. It will get all input from the base filepath.
    expressionDir = "./outputfiles/expression_measures/"
    genotypingDir = "./outputfiles/multisample_variants/"


    //yaml to parse yaml samplesheet file.
    def yaml = new Yaml()


    //input files
    //The samples param will be loaded. In the samples param are the fq files and the readgroups.
    samples = yaml.load(new FileInputStream(new File("./inputfiles/${params.sampleConfigFile}"))).samples
    referenceFasta = Channel.value([[id:"fasta"],file("./inputfiles/${params.referenceFasta}", checkIfExists: true)])
    referenceFastaFai = Channel.value([[id:"fastafai"],file("./inputfiles/${params.referenceFastaFai}", checkIfExists: true)])
    referenceFastaDict = Channel.value([[id: "fastadict"],[file("./inputfiles/${params.referenceFastaDict}", checkIfExists: true)]])

    //optional common fe input
    dbsnpVCF = Channel.value(file("./inputfiles/${params.dbsnpVCF}") ? file("./inputfiles/${params.dbsnpVCF}") : null)

    dbsnpVCFIndex = Channel.value(file("./inputfiles/${params.dbsnpVCFIndex}") ? file("./inputfiles/${params.dbsnpVCFIndex}") : null)

    refflatFile = Channel.value(file("./inputfiles/${params.refflatFile}") ? file("./inputfiles/${params.refflatFile}") : null)

    referenceGtfFile = Channel.value(file("./inputfiles/${params.referenceGtfFile}") ? file("./inputfiles/${params.referenceGtfFile}") : null)
    
    cpatLogitModel = Channel.value(file("./inputfiles/${params.cpatLogitModel}") ? file("./inputfiles/${params.cpatLogitModel}") : null)

    cpatHexChannel = Channel.value(file("./inputfiles/${params.cpatHex}") ? file("./inputfiles/${params.cpatHex}") : null)

    lncRNAdatabases = Channel.from(file("./inputfiles/*${params.lncRNAdatabases}*.txt") ? file("./inputfiles/*${params.lncRNAdatabases}*.txt") : null) //array


    //advanced option file input
    variantCallingRegions = Channel.value(file("./inputfiles/${params.variantCallingRegions}") ? file("./inputfiles/${params.variantCallingRegions}") : null)

    XNonParRegions = file("./inputfiles/${params.XNonParRegions}") ? file("./inputfiles/${params.XNonParRegions}") : null
    YNonParRegions = file("./inputfiles/${params.YNonParRegions}") ? file("./inputfiles/${params.YNonParRegions}") : null



//Defining  reads and readpairs
//"--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
//lists are made for read1, read2 and readpairs.
read_list = []

//each sample will be read
samples.each {sample -> sample.libraries.each {

    //each readpair will be read
    library -> library.readgroups.reads.each {
        readgroup -> 

            //reads will be stored in a variable. Read1 just gets read1 and read2 will only contain data if it is present.
            //If not it is an empty string
            read1 = readgroup.R1
            read2 = readgroup.R2 ? readgroup.R2: ""

            // Store both read1 and read2 in lists
            single_end = read2 != "" ? false : true
            if (read2 != "") {
            read_list << [[id: "${sample.id}_${library.id}", single_end: false],[file(read1, checkIfExists: true), file(read2, checkIfExists: true)]]
            }
            else {
                read_list << [[id: "${sample.id}_${library.id}", single_end: true],[file(read1, checkIfExists: true)]]
            }


        }
    }
}

//readlist and readpair stored as a list so it can be used in processes and be run parallel.


//"----------------------------------------------------------------------------------------------------------------------------------"
workflow {
    samplewf(read_list, referenceFasta, referenceFastaFai, referenceFastaDict, refflatFile)
    
    if (params.variantCalling) { 
        Calculateregionswf(samplewf.out.bam, XNonParRegions, YNonParRegions)
     }
    

        
}

