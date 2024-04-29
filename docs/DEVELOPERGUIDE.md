# DEVELOPER GUIDE

This is the developers guide for the RNA-seq workflow. The workflow is being developed with the purpose of geting information from the reads, including the gene expression.
The framework used to create this workflow is Nextflow.
The purpose of the guide is to give a bit of insight regarding working with the worfklow. This includes Architecture and dependencies.

# Table of Contents
1. [Layout](#layout)
   - [Workflow Image](#workflow-image)
2. [Dependencies](#dependencies)
   - [Workflow dependencies](#workflow-dependencies)
3. [Workflow](#workflow)
   - [Workflow](#workflow)
   - [Subworkflow](#subworkflow)
   - [Process](#process)
   - [Configuration file](#configuration-file)
   - [Dynamic resource allocation](#dynamic-resource-allocation)
3. [Testing](#testing)
   - [nf-test](#nf-test)
   - [Pytest workflow](#pytest-workflow)
4. [Development](#development)
   - [Adding features](#adding-features)

# Layout

## Workflow Image
![Workflow Image](https://github.com/lumc-sasc/wf-rnaseq/blob/main/docs/images/Workflow_Diagram.png)
The workflow image shows all the processes that exist in the current model of the pipeline. <br/>
Each color describes a different part of the pipeline and each shape describes either a file or a process. <br/>
The rectangle with the wave is the mandatory file block. The mandatory file block is the block that shows the mandatory files. <br/>
A rectangle with two vertical lines is the mandatory process. Those processes have to be run in the pipeline. <br/>
The parallel square is the between steps that happen between processes. <br/>
The diamond shape is all the true/false and yes/no statements. <br/>
The hexagon is all the optional files and variables that are either given as input or generated as output. <br/>
The non edged square is for all the processes that are not mandatory and are optional. <br/> <br/>

Fastqc subworkflow falls under the blue part of the workflow image. <br/>
Sample subworkflow falls under the yellow part of the workflow image. <br/>
Bammetrics subworkflow falls under the red/pink part of the workflow image. <br/>
All of variantcalling falls under the purple part of the workflow image. It is currently not finished yet. <br/>
LncRNAseq falls under the dark green part of the workflow image. <br/>
Expression quantification subworkflow falls under the dark red and grey part of the workflow image <br/><br/><br/>

## Directory structure.
A certain structure should be followed when addding processes, workflows and subworkflows. <br/>
A workflow should be added to the workflows directory, <br/>
a subworkflow should be added to the subworkflows directory, <br/>
and a process should be added in the local directory of the modules directory if it is a custom module. <br/>
The script that should be initiated is the main.nf file, with desired profile. <br/>



# Dependencies
## Workflow dependencies
For workflow dependencies, see user guide.

<hr><br/><br/>

# Workflow

## Workflow hub
The workflow hub is the nextflow file that can activate any pipeline with specific settings.
For example, one could make an entry case within the RNA-seq pipeline that handles test data,
and another entry where the genome is a large genome.
The following example shows how to write an hub: <br/>

```nextflow
//import workflows and reading modules
include { RNA_seq } from './workflows/RNA-seq'

//RNA-seq pipeline testcase. This sets the samplesheet to the test sampleshet.
workflow RNA_seq_pipeline_test {
   params.sampleConfigFile = "./test/data/samplesheet.yml"
   params.genome = "'Nextflow_test_human'"
   RNA_seq()
}

//RNA-seq pipeline GRCh38 genome case. This entry uses the GRCh38 genome.
workflow RNA_seq_pipeline_GRCh38 {
   params.genome = "'GRCh38'"
   RNA_seq()
}
    

```

## Workflow
The main workflow runs the workflow itself. It calls all the subworkflows that has to be run, with the exception of nested subworkflows. <br/>
The following example shows how to write a main workflow: <br/>
```nextflow
//This part describes the input files.
Samplesheet = params.samplesheet
Fasta = params.fasta
FastaFai = params.fastafai

//Start of the workflow iself.
workflow RNA-seq {
   // A subworkflow gets called up.
   subworkflow1(Samplesheet, Fasta, FastaFai)

   // A process that uses the output of the subworkflow and a variable from the configuration file.
   process1(subworkflow1.out.reads, params.strandedness)
}
```
<hr><br/><br/>

## Subworkflow
The subworkflow runs the processes of a certain part of the workflow. The subworkflows are used to catagorize everything. <br/>
This is why there is a subworkflow for sampling and a subworkflow for expression quantification. <br/>
The following example shows how to write a subworkflow: <br/>
```nextflow
//Start of the subworkflow.
workflow Sample {
   //It first takes the input that is given to it. Because it follows order rather than naming,
   //the name of the variable in the subworkflow can differ from variable in the main workflow. <br/>
   take:
   Samples
   Fasta
   Fai

   //It now runs every process and nested subworkflows that needs to run. This includes running process 1 and running process 2 with the output of process 1
   main:
   process1(Samples)

   process2(Process1.out.reads)

   //The emit is where output are given back to the main process.
   //The main workflow does use the variable name that has been described in th emit.
   emit:
   out_reads = process2.out.reads
}
```

<hr><br/><br/>

## Process
Processes run a certain task. A task can be adapter clipping or removing duplicate reads. <br/>
The following example shows how to write a process: <br/>
```nextflow
//Start of the process
process CUTADAPT {
   //Inputfiles of the process. It uses either a boolean, value or path. Also, multiple types of input can be given as a single input with the use of tuples.
   //Names also do not matter from workflow to process. This is because the process sets input based on order of given to the process.
   input:
      tuple val(meta), path(reads)
      path(fasta)

   //output of the process. It also binds a variable name to the output using emit setting and says if it is optional or not using optional setting (default false).
   output:
      tuple val(meta), path(cut_reads.fq.gz), emit: cut_raeds
      path(report.txt), emit: report, optional: true


   //Description of what container to use. It can be either put in here or in the config file.
   container 'https://depot.galaxyproject.org/singularity/cutadapt:4.6--py39hf95cd2a_1'

   //A conditional statement whether the process should execute.
   //If a process has a requirement on a channel, This statement can be used to put a conditional statement on the channel.
   //In this case, it looks if it is more than a single file. If it is a single file, it won't execute.
    when:
      reads.size() > 1

   //The code the process has to execute. It will first run groovy code till the """ block.
   script:
   //The use of the args argument allows for te use of additional command lines if needed.
   //This can be either an option for a tool or something that should happen after using the tool.
   def args = task.ext.args ?: ''


   def prefix = task.ext.prefix ?: "${meta.id}"
   def trimmed  = meta.single_end ? "-o ${prefix}.trim.fastq.gz" : "-o ${prefix}_1.trim.fastq.gz -p ${prefix}_2.trim.fastq.gz"

   //From this part on, linux code will be executed.
   """
   cutadapt \\
   $reads \\
   //In this case args contain the option --adapterForward and --adapterReverse with the adapters sequences.
   $args
   """
}
```

<hr><br/><br/>

## Configuration file
The configuration file handles all settings for the workflow and processes. This includes environment settings.
The User guide has an example of the nextflow.config file.
The following example shows how certain settings are set up within a config file.
```groovy
//Describing parameters. These can be used in any workflow and subworkflow as params.(variable)
params {
   refflat = "Filepath"
   strandedness = "RF"
   model = "neural networks"
}

//Describing settings within a process. The setting have influence over the processes.
process {
   ext.prefix = "RNA"

   //Describing settings for a specific process
   withName: FASTQC {
      //extra arguments for the process of FASTQC, this can be settings of fastqc or additional lines of bash code.
      ext.args = "-S"

      //Changing container.
      container = 'quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0'
   }


```

<hr><br/><br/>

## Dynamic resource allocation
Resources such as time, memory, and amount of cpu's, can be dynamically allocated based on things such as filesize and amount of files. <br/>
The following example shows how resources are dynamically allocated within the config file: <br/>
```groovy
//Describes that it is about settings within a process
process {
   //Describes which process has their settings changed.
   withName: STAR_ALIGN {
      //Allocation of memory. It grabs the index file its full path using the .target inbuilt function.
      //After that it gets the size of the file with .size() function.
      // After that the size of the file is multiplied by 1.3 times the variable based on the task attempt.
      //Each attempt will increase the multiplication with 0.1
      memory = {1.B * index.target.size() * 1.3 * (task.attempt * 0.1 + 0.9)}

      //Allocation of time. It first looks if it is a simple file or multiple files.
      //The reason for this being is that if one attempts to go through a reduce with only a single file, it will produce an error.
      //If there are multiple files, it will first grab all the full paths of the files using the .target.
      //It will then go through each instance with the use of stream.
      //While it goes through each instance, it will grab the fil size and add up the size with the total value with the use of .reduce.
      //After that it multiplies by the attempt of the process run.
      time = { reads.toList().size() > 1 ?
         1.ms * ((reads.target.stream().reduce(0, (x, y) -> x + y.size())) * task.attempt / 1000 + 300000) :
         1.ms * (reads.target.size() * task.attempt / 1000 + 125000)}

   }
}

```


# Testing

## nf-test
nf-test is a testing framework developed by some of the developers of Nextflow. It allows for testing the working of the workflows and processes. One of the things it can see for example is whether an output file is present.
Right now, there is an example of nf-test in the Htseq subdirectory within the test directory. It looks for the corrolation between the output file generated and the reference file. 
If the percentage is above 99%, it passes. Else, it will fail.

To be able to work with nf-test, nf-test dependency have to be installed alongside the ones for Nextflow. Follow the following code to install dependency:
```bash
conda activate nextflow
conda install -c bioconda nf-test
```
<br/>
nf-test file step by step walkthrough

```nextflow
nextflow_workflow {
}
//This part describes what type of testcase it is. In this case, it is ia workflow test so the test is wrapped in a nextflow_workflow test wrap.
//Everything is desribed within these code brackets.
```
<br/>


```nextflow
name "Test worfklow with Htseqcount"
script "../../main.nf"
workflow "RNA_seq"
//This part has the basic information, like what the name of the test will be, which file it should execute and what the name is of the workflow.
```
<br/>

```nextflow
stage {
   symlink "/exports/sascstudent/vperinbanathan"
}
//Staging of directory. This is needed, because otherwise it won't find the files neccesary, including inputfiles.
```
<br/>


```nextflow
test("Corrolation of Collect column counts has to be higher than 99.9%") {
}
//Descrption of the test and the execution of the test. Both everything that happens within the workflow execution as what happens after will happen within these code brackets.
```
<br/>

```nextflow
  when{
      params{
          outdir = "/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/test/outputfiles"
          sampleConfigFile = "/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/test/data/samplesheet.yml"
          genome = 'Nextflow_test_human'
      }
  }
//The when statement describes what should happen before executing the workflow. This includes setting environment and setting parameters.
```
<br/>


```nextflow
then {
   def reference_file_path = "/exports/sascstudent/vperinbanathan/WDL_RNA/output/expression_measures/fragments_per_gene/all_samples.fragments_per_gene"
   def Nextflow_file_path = "${params.outdir}/final_gene_count/report/report_collect_0.csv"

   assert workflow.success

   //CHECK HTSEQ-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   //runs the corrolation.py python script
   def execution_comparison = "python3 corrolation.py ${reference_file_path} ${Nextflow_file_path}".execute()
   //waits till the execution of the python script is done
   execution_comparison.waitFor()

   /saves the output text of the python script in a variable
   def corrolation = execution_comparison.in.text

   //asserts the output corrolation whether it is higher than 99.9
   assert Float.valueOf(corrolation) > 99.9

   //CHECK HTSEQ_END-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
}
//In the then statement, everything that should happen after workflow execution will be described in here. This includes running custom scripts in different code languages and asserting output.
```


<br/><br/>
For more information on how to work with nf-test, follow the following tutorial:
[Link to tutorial](https://www.nf-test.com/docs/getting-started/)
<hr><br/><br/>


## pytest workflow
pytest workflow is a testing framework developed by SASC. It was developed with the sole purpose to be able to test any workflow. Because it runs bash commands, it can work on any framework that works on bash line command.

To be able to work with pytest workflow, pytest workflow dependency have to be installed alongside the ones for Nextflow. Follow the following code to install dependency:
```bash
conda activate nextflow
conda install pytest-workflow
```

<br/>

(note to self, pytest workflow searches through every file for the name of the test)
Example of using pytest workflow

```yml
- name: Htseeq corrolation
   command: nextflow run main.nf -entry RNA_seq_pipeline --genome 'GRCh38'
files:
   - path: (path of outputfile)/Collected_Htseq_counts.csv

```

```python
import pathlib
import pytest
@pytest.mark.workflow('Htseq corrolation')
```


To be able to work with pytest workflow, a tutorial can be followed on the following link: [Link to tutorial](https://pytest-workflow.readthedocs.io/en/stable/)

# Development

## Adding features
When wanting to add a feature to the existing workflow and want to apply it globally, please open an issue to discuss what you would like to change. For own use cases, adding features to local environment poses no issues.
Please do write code documentation when adding a new feature and update when needed.






                                                                                                                                                                                                                                                                                                                                                                              





