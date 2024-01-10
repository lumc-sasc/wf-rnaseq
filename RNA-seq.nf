  nextflow.enable.dsl=2
   //testruncode ubuntu
   //nextflow run RNA-seq.nf --sampleConfigFile FunctionalPairedEnd.yml --referenceFasta reference.fasta --referenceFastaFai --reference.fasta.fai --referenceFastaDict reference.dict

    //include all processes and scripts
    include { samplewf } from "./subworkflows/sample.nf"
    include {Calculateregionswf} from "./subworkflows/Calculateregions.nf"
    include { preprocesswf } from "./subworkflows/preprocess.nf"
    include {SCATTERREGIONS as ScatterRegionsVariant} from "./custom_modules/chunked_scatter/scatterregions/main.nf"
    include { SingleSampleCallingwf } from "./subworkflows/VariantCalling/SingleSampleCalling.nf"
    include { MultiBamExpressionQuantificationwf } from "./subworkflows/expressionquantification/MultiBamExpressionQuantification.nf"
    include {GFFREAD as GffRead} from "./modules/gffread/main.nf"
    include {CPAT as Cpat} from "./custom_modules/cpat/main.nf"
    include {GFFCOMPARE as Gff_Compare_lnc} from "./modules/gffcompare/main.nf"
    include {MULTIQC as MultiQc} from './modules/multiqc/main.nf'
    import org.yaml.snakeyaml.Yaml
    
    
    
//"input output defining"    
//"-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"    

    //yaml to parse yaml samplesheet file.
    def yaml = new Yaml()


    //input files
    //The samples param will be loaded. In the samples param are the fq files and the readgroups.
    samples = yaml.load(new FileInputStream(new File("./inputfiles/${params.sampleConfigFile}"))).samples
    referenceFasta = [[id:"fasta"],file("./inputfiles/${params.referenceFasta}", checkIfExists: true)]
    referenceFastaFai = [[id:"fastafai"],file("./inputfiles/${params.referenceFastaFai}", checkIfExists: true)]
    referenceFastaDict = [[id: "fastadict"],[file("./inputfiles/${params.referenceFastaDict}", checkIfExists: true)]]

    //optional common fe input
    dbsnpVCF = file("./inputfiles/${params.dbsnpVCF}").exists() ?
        Channel.value(file("./inputfiles/${params.dbsnpVCF}")) :
        Channel.value([]).toList()

    dbsnpVCFIndex = file("./inputfiles/${params.dbsnpVCFIndex}").exists() ?
        Channel.value(file("./inputfiles/${params.dbsnpVCFIndex}")) : 
        Channel.value([]).toList()

    refflatFile = file("./inputfiles/${params.refflatfile}").exists() ? 
        Channel.value(file("./inputfiles/${params.refflatfile}")) : 
        null

    referenceGtfFile = file("./inputfiles/${params.referenceGtfFile}").exists() ?
        [[id: "refgtf"],[file("./inputfiles/${params.referenceGtfFile}")]] : 
        [[id: "refgtf"],[]]
    
    CpatLogitModel = file("./inputfiles/${params.cpatLogitModel}").exists() ? 
        Channel.value(file("./inputfiles/${params.cpatLogitModel}")) : Channel.value([]).toList()

    CpatHex = file("./inputfiles/${params.cpatHex}").exists() ?
        Channel.value(file("./inputfiles/${params.cpatHex}")) : Channel.value([]).toList()

    //lncRNAdatabases = file("./inputfiles/*${params.lncRNAdatabases}*.txt").exists() ? Channel.value(file("./inputfiles/*${params.lncRNAdatabases}*.txt")) : null //array


    //advanced option file input
    variantCallingRegions = file("./inputfiles/${params.variantCallingRegions}").exists() ?
        [[id: "variantCallingRegions"],[file("./inputfiles/${params.variantCallingRegions}")]] : null

    //variantcalling
    XNonParRegions = file("./inputfiles/${params.XNonParRegions}").exists() ?
        file("./inputfiles/${params.XNonParRegions}") : null

    YNonParRegions = file("./inputfiles/${params.YNonParRegions}").exists() ?
        file("./inputfiles/${params.YNonParRegions}") : null
    



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
            read_list << [[id: "${sample.id}_${library.id}", single_end: false, sample: "${sample.id}"],[file(read1, checkIfExists: true), file(read2, checkIfExists: true)]]
            }
            else {
                read_list << [[id: "${sample.id}_${library.id}", single_end: true,  sample: "${sample.id}"],[file(read1, checkIfExists: true)]]
            }


        }
    }
}

//readlist and readpair stored as a list so it can be used in processes and be run parallel.


//"----------------------------------------------------------------------------------------------------------------------------------"
workflow {
    //runs the sampleworkflow.
    samplewf(read_list, referenceFasta, referenceFastaFai, referenceFastaDict, refflatFile)

    //checks if variantcalling is applied and runs the following subworkflows if it is applied
    if(params.variantCalling) {
        //calculating regions
        Calculateregionswf(XNonParRegions, YNonParRegions, referenceFasta, referenceFastaFai, referenceFastaDict, variantCallingRegions)

        //calculating regions for preprocessing and running preprocess
        preprocessregions = variantCallingRegions != null ? variantCallingRegions : referenceFastaFai
        ScatterRegionsVariant(preprocessregions)
        preprocesswf(samplewf.out.bam, dbsnpVCF, dbsnpVCFIndex, referenceFasta, referenceFastaFai,
        referenceFastaDict, ScatterRegionsVariant.out.scatters)

        //running single sample variantcalling
        SingleSampleCallingwf(bam = preprocesswf.out.bam, bai = preprocesswf.out.bai, referenceFasta,
            referenceFastaFai, referenceFastaDict, dbsnpVCF, dbsnpVCFIndex, XNonParRegions, YNonParRegions,
            autosomalregions = Calculateregionswf.out.scatters)

    }
    

    //expression quantification
    MultiBamExpressionQuantificationwf(bam = samplewf.out.bam, referenceGtfFile, referenceFasta, referenceFastaFai)
    
    if (params.lncRNAdetection) {
        GffRead(MultiBamExpressionQuantificationwf.out.gtf.map {it[1]})
        Cpat(GffRead.out.gtf, CpatHex, CpatLogitModel, referenceFasta, referenceFastaFai)
        Gff_Compare_lnc(MultiBamExpressionQuantificationwf.out.gtf, referenceFasta << referenceFastaFai[1], referenceGtfFile)


    }
    MultiBamExpressionQuantificationwf.out.report.view()
    reports = samplewf.out.reports.join(MultiBamExpressionQuantificationwf.out.report)
    reports.map { return [it[1], it[2]].flatten()}.set{reports}
    MultiQc(reports,[],[],[])

    
}

