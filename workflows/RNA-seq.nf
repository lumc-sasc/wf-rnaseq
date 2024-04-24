//BEGIN INCLUDE STATEMENTS --------------------------------------------------------------------------------------------------------------

//This part includes the custom code that converts the input samplesheet to a nested list, grouped by samples and readpairs.
include {FILE_CHECK as File_Check}                  from "../modules/local/file_read/global/main.nf"

//This part includes all the subworkflows of the mandatory part of the workflow.
include { Samplewf }                                from "../subworkflows/sample.nf"
include { MultiBamExpressionQuantificationwf }      from "../subworkflows/expressionquantification/MultiBamExpressionQuantification.nf"

//This part includes all the subworkflows of the variantcalling part of the workflow.
include {Calculateregionswf}                        from "../subworkflows/Calculateregions.nf"
include { Preprocesswf }                            from "../subworkflows/preprocess.nf"
include { SingleSampleCallingwf }                   from "../subworkflows/VariantCalling/SingleSampleCalling.nf"

//This part includes all processes of the mandatory part of the workflow.
include {MULTIQC as MultiQc}                        from '../modules/nf-core/multiqc/main.nf'

//This part includes all the processes of the variantcalling part of the workflow.
include {SCATTERREGIONS as ScatterRegionsVariant}   from "../modules/local/chunked_scatter/scatterregions/main.nf"

//This part includes all the processes from the lncRNAdetection part of the workflow.
include {GFFREAD as GffRead}                        from "../modules/nf-core/gffread/main.nf"
include {CPAT as Cpat}                              from "../modules/local/cpat/main.nf"
include {GFFCOMPARE as Gff_Compare_lnc}             from "../modules/nf-core/gffcompare/main.nf"

//END INCLUDE STATEMENTS---------------------------------------------------------------------------------------------------------------

//Start of Workflow
workflow RNA_seq {
        //BEGIN DEFINITION INPUT FILES ------------------------------------------------------------------------------------------------

        //Definition of Samplesheet. It will run a custom function that converts samplesheet file to a nested list that is grouped by samples and readpairs.
        fastq_grouped_list = File_Check()
        

        /*defines genomeconfig. It will look in the igenomes config file and the params config file. Within the params.config file it will look for
        the genomes parameter. It is the base directory of where all the genomes are located. It will then check the genome parameter to see which genome is used.
        It will then look in the igenomes config file to see in what subdirectory the files are present and grabs the files if it exists.
        */
        referenceFasta                      = [[id: "Genome"], file(params.genomes[ params.genome ][ 'fasta' ], checkIfExists: true)]
        referenceFastaFai                   = [[id: "Genome"], file(params.genomes[ params.genome ][ 'fastaFai' ], checkIfExists: true)]
        referenceFastaDict                  = [[id: "Genome"], file(params.genomes[ params.genome ][ 'fastaDict' ], checkIfExists: true)]
        refflatFile                         = file(params.genomes[ params.genome ] [ 'refflat']).exists() ? [[id: "Genome"], file(params.genomes[ params.genome ][ 'refflat' ])] : [[id: "Genome"],[]]
        referenceGtfFile                    = file(params.genomes[ params.genome ][ 'referenceGTF' ]).exists() ? [[id: "Genome"], file(params.genomes[ params.genome ][ 'referenceGTF' ])] : [[id: "Genome"], []]


        //defines regions. Optional files that are only used in the variantcalling part of the workflow.
        variantCallingRegions               = file("$baseDir/$params.variantCallingRegions").exists() ? [[id: "Region"], file(params.variantCallingRegions)] : []
        xNonParRegions                      = file("$baseDir/$params.xNonParRegions").exists()        ? [[id: "Region"], file(params.xNonParRegions)] : []
        yNonParRegions                      = file("$baseDir/$params.yNonParRegions").exists()        ? [[id: "Region"], file(params.yNonParRegions)] : []

        //defines VCF. Optional files that are only used in the variantcalling part of the workflow.
        dbsnpVCF                            = file("$baseDir/$params.dbsnpVCF").exists()              ? [[id: "Vcf"], file(params.dbsnpVCF)]          : [[id: "empty"],[]]
        dbsnpVCFIndex                       = file("$baseDir/$params.dbsnpVCFIndex").exists()         ? [[id: "Vcf"], file(params.dbsnpVCFIndex)]     : [[id: "empty"],[]]

        //defines cpat. Needed in order for lncRNAdetection part of the workflow to work properly.
        cpatLogitModel                      = file("$baseDir/$params.cpatLogitModel").exists()        ? [[id: "cpat"], params.cpatLogitModel]   : []
        cpatHex                             = file("$baseDir/$params.cpatHex").exists()               ? [[id: "cpat"], params.cpatHex]          : []

        //END DEFINITION INPUT FILES --------------------------------------------------------------------------------------------------

        //runs the sampleworkflow.
        Samplewf(fastq_grouped_list, referenceFasta, referenceFastaFai, referenceFastaDict, referenceGtfFile , refflatFile)


        //START OF VARIANTCALLING -----------------------------------------------------------------------------------------------------
        if(params.variantCalling) /*true false statement*/ { 
            //Runs regions subworkflow, which calculates the regions  that will be used on the Single sample variantcalling subworkflow
            Calculateregionswf(xNonParRegions, yNonParRegions, referenceFasta, referenceFastaFai,
                                referenceFastaDict, variantCallingRegions) 

            //Preprocess regions is defined depending on if variantcallingregions is empty or not.
            preprocessregions = variantCallingRegions.size() > 0 ? variantCallingRegions : referenceFastaFai

            // Scatter regions for preprocesswf is being run.
            ScatterRegionsVariant(preprocessregions)

            //preprocess workflow is being run.
            Preprocesswf(Samplewf.out.bam, dbsnpVCF, dbsnpVCFIndex, referenceFasta, referenceFastaFai,
            referenceFastaDict, ScatterRegionsVariant.out.scatters)

            //running single sample variantcalling
            SingleSampleCallingwf(bam = Preprocesswf.out.bam, bai = Preprocesswf.out.bai, referenceFasta,
                referenceFastaFai, referenceFastaDict, dbsnpVCF, dbsnpVCFIndex, xNonParRegions, yNonParRegions,
                autosomalregions = Calculateregionswf.out.scatters)

        }
        //END OF VARIANTCALLING -------------------------------------------------------------------------------------------------------
        

        //Calls the expression quantification subworkflow. It will generate count tables that show the gene expression.
        MultiBamExpressionQuantificationwf(bam = Samplewf.out.bam, referenceGtfFile, referenceFasta, referenceFastaFai)
        
        //Checks if lncRNAdetection is true, if it is true it will run GffRead, Cpat and Gff_Compare. Requires cpatHex and cpatLogitModel in order to work properly.
        if (params.lncRNAdetection) {
            GffRead(MultiBamExpressionQuantificationwf.out.gtf.map {it[1]})
            Cpat(GffRead.out.gtf, cpatHex, cpatLogitModel, referenceFasta, referenceFastaFai)
            Gff_Compare_lnc(MultiBamExpressionQuantificationwf.out.gtf, referenceFasta << referenceFastaFai[1], referenceGtfFile)


        }
        
        //Reports are being merged together.
        reports = Samplewf.out.reports.join(MultiBamExpressionQuantificationwf.out.report)

        //Report identification label is being removed since it can't be used in MultiQC.
        reports.map{return it.subList(1, it.size()).flatten()}.set{reports}

        //Run multiQC so that every report is shown in a single html page.
        MultiQc(reports,[],[],[])


    
}

