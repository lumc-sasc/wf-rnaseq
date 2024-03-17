process HTSEQ_COUNT_COMPARISON {
    
    output:
    path("*.txt"), emit: corrolation
    
    """
    #!/usr/bin/env python
    import csv

    def extract_gene_number(header):
        return header.split('gene')[-1]

    with open('/exports/sascstudent/vperinbanathan/WDL_RNA/output/expression_measures/fragments_per_gene/all_samples.fragments_per_gene', 'r') as WDL, open('/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/outputfiles/final_gene_count/report/report_collect_0.csv', 'r') as Nextflow:

        reader = csv.reader(WDL, delimiter="\t")
        header = next(reader)
        sorted_header = sorted(header, key=extract_gene_number)
        sorted_indices = [header.index(col) for col in sorted_header]
        rows = list(reader)
        WDL_lines = sorted(rows, key=lambda row: row[0])
        WDL_line = len(WDL_lines) -1
        
        line_count = len(WDL_lines) * len(WDL_lines[0])
        

        reader = csv.reader(Nextflow, delimiter="\t")
        header = next(reader)
        sorted_header = sorted(header, key=extract_gene_number)
        sorted_indices = [header.index(col) for col in sorted_header]
        rows = list(reader)
        Nextflow_lines = sorted(rows, key=lambda row: row[0])
        Nextflow_line = len(Nextflow_lines) -1
        
        line_corrolation = 0

        while len(WDL_lines) != 0 and len(Nextflow_lines) != 0:
            WDL_instance = WDL_lines[WDL_line]
            Nextflow_instance = Nextflow_lines[Nextflow_line]

            if WDL_instance[0] == Nextflow_instance[0]:
                corrolation = 0
                for WDL_value, Nextflow_value in zip(WDL_instance[1:] , Nextflow_instance[1:]):

                    if float(WDL_value) == float(Nextflow_value):
                        corrolation += 1
                    line_corrolation += corrolation / len(WDL_instance[1:])

                del WDL_lines[-1]
                del Nextflow_lines[-1]
                WDL_line -= 1
                Nextflow_line -= 1

            elif int(WDL_instance[0].strip("ENSG")) > int(Nextflow_instance[0].strip("ENSG")):
                WDL_line -= 1
                del WDL_lines[-1]

            else:
                Nextflow_line -= 1
                del Nextflow_lines[-1]
    output_corrolation = line_corrolation/line_count*100
    with open('corrolation.txt', 'w') as file:
        file.write(str(output_corrolation))
    """
}
