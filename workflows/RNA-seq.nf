//All subworkflows and processes/modules are loaded in.
include {FILE_CHECK as File_Check}                  from "../custom_modules/file_read/global/main.nf"
include { Samplewf }                                from "../subworkflows/sample.nf"
include {Calculateregionswf}                        from "../subworkflows/Calculateregions.nf"
include { Preprocesswf }                            from "../subworkflows/preprocess.nf"
include {SCATTERREGIONS as ScatterRegionsVariant}   from "../custom_modules/chunked_scatter/scatterregions/main.nf"
include { SingleSampleCallingwf }                   from "../subworkflows/VariantCalling/SingleSampleCalling.nf"
include { MultiBamExpressionQuantificationwf }      from "../subworkflows/expressionquantification/MultiBamExpressionQuantification.nf"
include {GFFREAD as GffRead}                        from "../modules/gffread/main.nf"
include {CPAT as Cpat}                              from "../custom_modules/cpat/main.nf"
include {GFFCOMPARE as Gff_Compare_lnc}             from "../modules/gffcompare/main.nf"
include {MULTIQC as MultiQc}                        from '../modules/multiqc/main.nf'

//"----------------------------------------------------------------------------------------------------------------------------------"
//Start of Workflow

workflow RNA_seq {
        //BEGIN DEFINITION INPUT FILES ------------------------------------------------------------------------------------------------

        sample_read_list = File_Check()

        //defines genomeconfig
        referenceFasta                      = [[id: "Genome"], file(params.genomes[ params.genome ][ 'fasta' ], checkIfExists: true)]
        referenceFastaFai                   = [[id: "Genome"], file(params.genomes[ params.genome ][ 'fastaFai' ], checkIfExists: true)]
        referenceFastaDict                  = [[id: "Genome"], file(params.genomes[ params.genome ][ 'fastaDict' ], checkIfExists: true)]
        refflatFile                         = [[id: "Genome"], file(params.genomes[ params.genome ][ 'refflat' ])]
        referenceGtfFile                    = file(params.genomes[ params.genome ][ 'referenceGTF' ]).exists() ? [[id: "Genome"], file(params.genomes[ params.genome ][ 'referenceGTF' ])] : [[id: "Genome"], []]

        //defines regions
        variantCallingRegions               = file("$baseDir/$params.variantCallingRegions").exists() ? [[id: "Region"], file(params.variantCallingRegions)] : []
        xNonParRegions                      = file("$baseDir/$params.xNonParRegions").exists()        ? [[id: "Region"], file(params.xNonParRegions)] : []
        yNonParRegions                      = file("$baseDir/$params.yNonParRegions").exists()        ? [[id: "Region"], file(params.yNonParRegions)] : []

        //defines VCF
        dbsnpVCF                            = file("$baseDir/$params.dbsnpVCF").exists()              ? [[id: "Vcf"], params.dbsnpVCF]          : []
        dbsnpVCFIndex                       = file("$baseDir/$params.dbsnpVCFIndex").exists()         ? [[id: "Vcf"], params.dbsnpVCFIndex]     : []

        //defines cpat
        cpatLogitModel                      = file("$baseDir/$params.cpatLogitModel").exists()        ? [[id: "cpat"], params.cpatLogitModel]   : []
        cpatHex                             = file("$baseDir/$params.cpatHex").exists()               ? [[id: "cpat"], params.cpatHex]          : []

        //END DEFINITION INPUT FILES --------------------------------------------------------------------------------------------------

        //runs the sampleworkflow.
        Samplewf(sample_read_list, referenceFasta, referenceFastaFai, referenceFastaDict, referenceGtfFile , refflatFile)


        //START OF VARIANTCALLING -----------------------------------------------------------------------------------------------------
        if(params.variantCalling) /*true false statement*/ { 
            Calculateregionswf(xNonParRegions, yNonParRegions, referenceFasta, referenceFastaFai,
                                referenceFastaDict, variantCallingRegions) //Workflow calculates the regions using bed files or reference

            //Preprocess regions is defined depending on if variantcallingregions is empty or not.
            preprocessregions = variantCallingRegions != null ? variantCallingRegions : referenceFastaFai

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
        

        //expression quantification
        MultiBamExpressionQuantificationwf(bam = Samplewf.out.bam, referenceGtfFile, referenceFasta, referenceFastaFai)
        
        //Checks if lncRNAdetection is true, if it is true it will run GffRead, Cpat and Gff_Compare
        if (params.lncRNAdetection) {
            GffRead(MultiBamExpressionQuantificationwf.out.gtf.map {it[1]})
            Cpat(GffRead.out.gtf, cpatHex, cpatLogitModel, referenceFasta, referenceFastaFai)
            Gff_Compare_lnc(MultiBamExpressionQuantificationwf.out.gtf, referenceFasta << referenceFastaFai[1], referenceGtfFile)


        }
        
        //Reports are being merged together.
        reports = Samplewf.out.reports.join(MultiBamExpressionQuantificationwf.out.report)

        //Report identification label is being removed since it can't be used in MultiQC.
        reports.map{return it.subList(1, it.size()).flatten()}.set{reports}
        MultiQc(reports,[],[],[])


    
}

