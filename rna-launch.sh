#!/bin/bash
#SBATCH --mem 5G
#SBATCH -c 1
#SBATCH -t 10:00:00


# Use a conda environment where you have installed Nextflow
# (may not be needed if you have installed it in a different way)
conda activate nextflow

nextflow run RNA-seq.nf -resume
