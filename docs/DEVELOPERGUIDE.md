# DEVELOPER GUIDE

This is the developers guide for the RNA-seq workflow. The workflow is being developed with the purpose of geting information from the reads, including the gene expression.
The framework used to create this workflow is Nextflow.
The purpose of the guide is to give a bit of insight regarding working with the worfklow. This includes Architecture and dependencies.

# Table of Contents
1. [Layout](#layout)
   - [Directory Layout](#directory-layout)
      - [Structure](#structure)
      - [Modules](#modules)
   - [Workflow Image](#workflow-image)
   - [Writing code](#writing-code)
      - [Editing Workflows](#editing-workflows)
      - [Creating Processes](#creating-processes)
      - [Custom Code](#custom-code)
      - [Building Profiles](#building-profiles)
2. [Dependencies](#dependencies)
   - [Understanding of Nextflow](#understanding-of-nextflow)
   - [Workflow dependencies](#workflow-dependencies)
3. [Testing](#testing)
   - [nf-test](#nf-test)
   - [Pytest workflow](#pytest-workflow)
4. [Development](#development)
   - [Adding features](#adding-features)

# Layout

## Workflow Image
![Workflow Image](https://github.com/lumc-sasc/wf-rnaseq/blob/main/Workflow_Diagram.png)
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

## Directory Layout
The layout of the directory is very important. This is to keep the directory clean and readable.

### Structure
The pipeline consist of a structure. The top level is the hub. The hub is the main.nf file in the main folder. <br/>
The hub contains all the workflows that can be executed. This is if one wants to run a certain workflow. <br/>
The second level is the workflow itself. The workflow is the main part of the pipeline and is the most vital part of the pipeline. <br/>
The third level is the subworkflows. Subworkflows are workflows defined in subworkflows, that does a specific part of the pipeline. <br/>
The fourth level is the modules. Modules are tasks that are being executed within the sub- workflows. <br/><br/>

### Modules
There are two variants of the modules. The nf-core modules and custom modules. <br/>
It is strictly frowned upon to change anything within a nf-core module. This is because nf-core modules is a subrepository. <br/>
Another person can run into errors because they downloaded the nf-core modules directory which doesn't have the changes. <br/>
Instead, a custom module variant of the nf-core module has to be created, which is then stored in a seperate directory. <br/>
The custom modules can be either put inside the modules folder, where nf-core modules will have a seperate folder then, <br/>
or be put in a different folder outside of the module folder. <br/><br/>

### Config files
The config files consist of multiple layers. The file in the main layer is the nextflow.config file. <br/>
The nextflow.config file handles the environent settings, aswell calls up the other config files. <br/>
The config files that nextflow.config file calls upon are the tasks, parameters, and igenomes config files. <br/>
The tasks config file is the config file that contains the settings of every process. <br/>
This also includes settings regarding resources, and if the output should be put in the output directory. <br/>
The parameters config file contains all the parameters that are not environment based. <br/>
If a certain variable have to be used over multiple files, it is more proper to set the variable up as a parameter. <br/>
This is only if the pipeline won't break from a change in the parameter. <br/>
The igenomes config file is a library where each genome and its files are describes. <br/>
This serves as a longterm library to use genomes that will be reused, but will not be used every time. <br/> <br/> <br/>


## Writing code

### Editing Workflows
Workflows can edited accordingly to ones needs. Adding processes won't have influence on the rest of the pipeline/workflow. <br/>
However, if one wants to process data more by adding processes, they have to keep in mind that they have to put the correct channels accordingly. <br/>
When removing processes, one has to keep in mind that a process data is not only used downstream, but that sometimes the report is also given downstream. <br/>
One has to properly remove everything associatd to the process in order to prevent errors <br/><br/>


### Creating Processes
Processes should be created with the general consensus in mind. This means using metadata and the filepath as input. <br/>
The reason being is that it would require additional work outside the process scope to make sure the input data fits the structure needed for the process. <br/>
Most processes use metadata, and that causes almost everyone to apply metadata to their input. <br/>
Output should always have an emit name. This is because some may want to use the output for other processes or want to manipulate it some way. <br/>
Keep in mind when setting containers, that the only option is singularity. Alternative of containers being conda. <br/>
Docker containers can be run in singularity, thus docker containers pose no problem to be used. <br/><br/>


### Custom Code
Custom code should only be used if There is no alternative way to solve an issue. <br/>
This is because custom code can increase complexity of the pipeline, which in turn makes it more difficult for other developers to work on it. <br/>
If custom code is applied, the exact steps have to be properly described so that the other developers know what each line does. <br/>
Custom code has to be put inside a groovy class inside the lib folder. This way, everything is kept clean. <br/><br/><br/>

### Building Profiles
One can create profiles if they need different settings for each case scenario. <br/>
Profiles are mostly meant for changes in environment and task arguments. <br/>
They are not meant to make changes in parameters, tho they can still be used for that. <br/>
If one wnats to create large differences in profiles with different config files, one should create directories for each profile and its conig files <br/>
This keeps everything nicely organized and makes sure that if something is wrong with a profile, one knows where to look. <br/><br/>

# Dependencies


## Understanding of Nextflow
When a developer wants to work on the workflow, they need to have a solid understanding of the basisc of Nextflow. This is because the workflow is written in Nextflow and contains subjects like channels. Nextflow works different regarding data submission to processes and data manipulation, which is why one must have a minimum level understand to start working on the workflow. A training can be followed on the following link to get a grasp on Nextflow:
[Link to training](https://training.nextflow.io/)

It is also recommended to do the advanced training. This is mostly because subjects like configuration and data manipulation is handled in the advanced course. Data manipulation, like grouping, is applied within the RNA-seq workflow.

## Workflow dependencies
For workflow dependencies, see user guide.

<hr><br/><br/>

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
   def corrolation = "python3 corrolation.py ${reference_file_path} ${Nextflow_file_path}".execute()
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




To be able to work with pytest workflow, a tutorial can be followed on the following link: [Link to tutorial](https://pytest-workflow.readthedocs.io/en/stable/)

# Development

## Adding features
When wanting to add a feature to the existing workflow and want to apply it globally, please open an issue to discuss what you would like to change. For own use cases, adding features to local environment poses no issues.
Please do write code documentation when adding a new feature and update when needed.






                                                                                                                                                                                                                                                                                                                                                                              





