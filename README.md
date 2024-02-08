# RNA-seq

RNA-seq is a nextflow pipeline that does analysis on transcriptomic sequencing data.

## Installation

### Dependencies Installation
To download the neccesary dependencies, conda can be used to achieve this.

following dependencies that can be installed on conda are:
Nextflow 23.10.1
Singularity 3.8.6

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

### Pipeline Installation
run the following command in the terminal to install the pipeline.

```bash
git clone https://github.com/lumc-sasc/wf-rnaseq.git
```

## Usage

### Input and configurations
The standard map for input is the inputfiles directory. In the parameters config file a different path can be given.
However, do keep in mind that if the inputfiles is in another subbranch, you will need to give the path from your directory to the destined directory, rather than from root directory.
The parameters config file gives all possible options within the pipeline and can be changed accordingly.
Changes can cause error if the inputfiles don't align with said changes.
Within the subworkflow config files with the tasks, you can change resources and queue.
Aswell additional commands to be used can be added in the process config within the subworkflow config files.


### Execution
```bash
nextflow run RNA-seq.nf
```

## Contribution
Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
[MIT](https://github.com/lumc-sasc/wf-rnaseq/blob/main/LICENSE)
