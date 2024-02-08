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
