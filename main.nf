//import workflows and reading modules
include { RNA_seq } from './workflows/RNA-seq'

//RNA-seq pipeline
workflow RNA_seq_pipeline {
    RNA_seq()
}
    