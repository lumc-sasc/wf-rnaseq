# RNA-seq

RNA-seq is a nextflow pipeline that does analysis on transcriptomic sequencing data.

# Table of Contents

1. [Installation](#installation)
   - [Dependencies Installation](#dependencies-installation)
   - [Pipeline Installation](#pipeline-installation)
3. [Usage](#usage)
   - [Input and configurations](#input-and-configurations)
     - [Genome Parameters](#genome-parameters)
     - [Input Paramters](#input-parameters)
     - [Mandatory Variables](#mandatory-variables)
     - [Boolean Variables](#boolean-variables)
     - [Optional Variables](#optional-variables)
     - [Environment Variables](#environment-variables)
   - [Execution](#execution)
5. [Contribution](#contribution)
6. [License](#license)

<br/><br/><br/>
# Installation

## Dependencies Installation
To download the neccesary dependencies, conda can be used to achieve this.<br>

following dependencies that can be installed on conda are:<br>
Nextflow 23.10.1<br>
Singularity 3.8.6<br>

Creation of conda environment in bash:
```bash
#installation of conda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh miniconda.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -u -p #(filepath)
source ~/.bashrc

#installation of the packages
conda create -n nextflow
conda activate nextflow
conda config -add channels bioconda
conda config -add channels conda-forge
conda config -set channel_priority strict
conda install -c bioconda nextflow
conda install -c conda-forge singularity

```
<br/><br/>
## Pipeline Installation
run the following command in the terminal to install the pipeline.

```bash
git clone https://github.com/lumc-sasc/wf-rnaseq.git
```
<br/><br/>
## Module Installation
Module installation will be done through nf-core with the modules.json file. <br/>
Reason being is that this way only the modules needed will be installed, rather than installing the complete library <br/>
Follow the following commands to install the modules (only after installing the workflow).
```bash
conda activate nextflow
conda install bioconda::nf-core
nf-core modules list local
```

## Setting export paths
Exports paths have to be set to handle the temporary directory. If no export paths are set, errors can occur due to temporary directory space running out if it is set to the wrong folder <br/>
The export paths can be set in the following way:
```bash
nano ~/.bashrc
#Go to the bottom of the file and put down the following lines, including what filepath you want to use for the temporary directory
export NXF_TEMP=(filepath to TEMPDIR)
export SINGULARITY_TMPDIR=(filepath to TEMPDIR)
export TEMP=(filepath to TEMPDIR)
export _JAVA_OPTIONS=-Djava.io.tmpdir=(filepath to TEMPDIR)
#Exit and save file.
source ~/.bashrc
```
<br/><br/><br/>
# Usage

## Input and configurations
Input can be defined in the parameters config file using filepaths. The exception being the reference genome files. <br/>

The reference files work through a library system using the genome parameter, where the name of the genome will be looked up in the library. <br/>
The library file is the igenomes config file. All genomes that will be used are described in there, including where the files are.<br/>
It is preferred to have all the genomes in one common directory, as this will keep everything organized and easily maintained. <br/>
The genome for use can be either filled in the parameter config file or in the command line within linux.<br/>

There are a lot of parameters that can be filled in. Below is the list with parameters and what purpose each of them have.<br/><br/>

### Genome Parameters
<hr>
genome                       : What genome is to be used. Default is null <br/>
<hr>
genomes_base                 : Where the base directory for the genomes are located <br/>
<hr><br/>

### Input Parameters
<hr>
SampleConfigFIle             : Samplesheet file. Currently supported: yaml and csv. Default is nextflow library test file<br/>
<hr>
starIndex                    : Star index. Optional input file which will run star align if given. Default is null. <br/>
<hr>
hisat2                       : hisat2 directory. Optional input directory which will run hisat2 if given. Default is null. <br/>
<hr>
dbsnpVCF                     : Single Nucleotide Polymorphism database vcf file. Optional file for the preprocess and variantcalling workflow. Default is empty list (null). <br/>
<hr>
dbsnpVCFIndex                : Single Nucleotide Polymorphism database vcf index file. Optional file for the preprocess and variantcalling workflow. Default is empty list (null). <br/>
<hr>
cpatLogitModel               : Coding-Potential Assessment Tool logit model. Mandatory file if one plans to run lncRNAdetection part of the pipeline. Default is empty list (null). <br/>
<hr>
cpatHex                      : Coding-Potential Assessment Tool Hex file. Mandatory file if one plans to run lncRNAdetection part of the pipeline. Default is empty list (null). <br/>
<hr>
lncRNAdatabases              : Long non-coding RNAs. Supposed to be implemented in Gff_compare_lnc in the lncRNAdetection part of the pipeline. However, it is not implemented. Default is empty list (null). <br/>
<hr>
variantCallingRegions        : Regions for variantcalling. Used to calculate regions and in the preprocessing. Default is null. <br/>
<hr>
xNonParRegions               : Regions for the x chromosome. Used to calculate regions and in the variantcalling. Default is null. <br/>
<hr>
yNonParRegions               : Regions for the y chromosome. Used to calculate regions and in the variantcalling. Default is null. <br/>
<hr>
rrna_intervals               : Intervals file. Used for the collectrnaseqmetrics process. Default is empty list (null). <br/>
<hr><br/>

### Mandatory Variables
<hr>
strandedness                 : Type of strand that is used. Can be either FR, RF or None. Default is RF. <br/><br/>
<hr>

### Boolean Variables
<hr>
variantCalling               : Boolean statement that will activate the variantcalling part of the pipeline if true. Default is false. <br/>
<hr>
dgeFiles                     : Not implemented boolean statement. Yet to implement in creating design matrix if true. Default is false. <br/>
<hr>
umiDeduplication             : Boolena statement that will activate the deduplication part of the pipeline if true. Default is true. <br/>
<hr>
get_output_stats             : Boolean statement. If true, will generate output stats in deduplication. Default is false. <br/>
<hr>
star_ignore_sjdbgtf         : Boolean statement. If true, will ignore using gtf file in star_align. Default is true. <br/>
<hr>
splitSplicedReads           : Boolean statment. If true, will run splitNCigarReads part of the workflow. Default is false. <br/>
<hr>
mergeVcf                    : Boolean statement. If true, will either run Combinegvcf process or Mergevcf process depending on the gvcf. Default is true. <br/>
<hr>
gvcf                        : Boolean statement. If true, will run Combinevcf process. Also requires x regions and y regions. Default is false. <br/>
<hr>
runStringtieQuantification  : Boolean statement. If true, it will run the stringtie quantification within the multibam expression quantification. Default is true. <br/>
<hr>
lncRNAdetection             : Boolean statement. If true, it will run the lncRNAdetection part of the pipeline. Default is false. <br/>
<hr><br/>

### Optional Variables
<hr>
adapterForward              : Forward adapter for adapterclipping in cutadapt. If present, will run cutadapt. Default: AGATCGGAAGAG. <br/>
<hr>
adapterReverse              : Reverse adapter for adapterclipping in cutadapt. If present, will run cutaapt. Default: AGATCGGAAGAG. <br/>
<hr>
contaminations              : Contaminations for adapterclipping cutadapt. If present, will run cutadapt. Default is empty list (null). <br/>
<hr>
seq_center                  : Sequencing center, used for star align. Default is empty list (null). <br/>
<hr>
seq_platform                : Sequencing platform, used for star align. Default is illumina.
<hr>
scatter_size                : parameter for variant. Will be discontinued in near future. Default is 0. <br/>
<hr><br/>

### Environment Variables
<hr>
tempdir                     : Directory to store temporary files from processes.<br/>
<hr>
cachedir                    : Directory where the singularity containers are located. <br/>
<hr>
basedir                     : Directory where the main script is located. <br/>
<hr>
outdir                      : Directory where the outputfiles are located. <br/>
<hr><br/><br/>

### Nextflow.config file.
All global configurations are in the nextflow.config file. The format of a config file looks like the following structure:
```nextflow

//Include Temporary directory
params.tempdir = "/exports/sacstudent/vperinbanathan/nextflow_pipeline_testzone/TEMP_DIR"
params.cachedir = "/exports/sascstudent/vperinbanathan/programmas/singularity_containers"
params.basedir = "/exports/sacstudent/vperinbanathan/nextflow_pipeline_testzone"


singularity {
    enabled = true
    autoMounts = true
    cacheDir = "${params.cachedir}"
}

env {
    TMPDIR = "${params.tempdir}"
}

process.executor = 'slurm'

cleanup = 'eager'
baseDir = "${params.basedir}"

//config file tasks
includeConfig 'config/tasks.config'
includeConfig 'config/parameters.config'
includeConfig 'config/input_config/igenomes.config'

```
An Example of a global configuration shown in this configuration file is the cleanup statement. It has three options: true, false, and eager. <br/> <br/>
If cleanup is set to true, it will remove temporary files as soon the pipeline is finished executing. <br/>
If cleanup is set to false, it will not remove temporary files. <br/>
If cleanup is set to eager, it will remove temporary files as soon they are not needed anymore by the workflow.

<br/>
Another thing that is handled in the global configuration is the container settings. In this case settings for singularity are set. <br/>
In this case singularity is enabled with automount. The cache directory of where the containers are located are also given.
<hr><br/><br/>

## Execution
if the required files and the dependencies are installed, and if the parameters have been set, you can run the pipeline with the following command.
```bash
nextflow run RNA-seq.nf -entry RNA_seq_pipeline --genome 'Nextflow_test_human'
```
<hr/><br/>

### Add additional parameters
Adding additional parameters can be done in two ways. <br/>
The first way is to add arguments in the command line. See below for following example with adapters and runStringtieQuantification:
```bash
nextflow run RNA-seq.nf -entry RNA_seq_pipeline --genome 'Nextflow_test_human' --adapterForward AGATCGGAAGAG --adapterReverse AGATCGGAAGAG --runStringtieQuantification true 
```

The secon way is to create an parameter file.

# Contribution
Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.

# License
[MIT](https://github.com/lumc-sasc/wf-rnaseq/blob/main/LICENSE)
