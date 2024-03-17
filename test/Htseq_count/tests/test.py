#!/usr/bin/env python
import csv

stored_value = []

def extract_gene_number(header):
    return header.split('gene')[-1]

with open('/exports/sascstudent/vperinbanathan/WDL_RNA/output/expression_measures/fragments_per_gene/all_samples.fragments_per_gene', 'r') as WDL, open('/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/outputfiles/final_gene_count/report/report_collect_0.csv', 'r') as Nextflow:

    data = [line for line in csv.reader(WDL, delimiter="\t")]
    sorted_header = sorted(data[0])
    indexes = [data[0].index(column) for column in sorted_header]
    WDL_lines = []
    for row in data[1:]:
        line = []
        for part in indexes:
            line.append(row[part])
        WDL_lines.append(line)
    WDL_line = len(WDL_lines) -1
    
    line_count = len(WDL_lines)

    data = [line for line in csv.reader(Nextflow, delimiter="\t")]
    sorted_header = sorted(data[0])
    indexes = [data[0].index(column) for column in sorted_header]
    Nextflow_lines = []
    for row in data[1:]:
        line = []
        for part in indexes:
            line.append(row[part])
        Nextflow_lines.append(line)
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
                else:
                    if float(WDL_value) > float(Nextflow_value):
                        stored_value.append(float(WDL_value) - float(Nextflow_value))
                        print(WDL_instance[0], ": ", float(WDL_value) - float(Nextflow_value), "WDL: ", WDL_value, "\t", "Nextflow: ", Nextflow_value)
                        
                    else:
                        stored_value.append(float(Nextflow_value) - float(WDL_value))
                        print(WDL_instance[0], ": ", float(Nextflow_value) - float(WDL_value), "WDL: ", WDL_value, "\t", "Nextflow: ", Nextflow_value)
                    
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
    file.write(str(float("{:.2f}".format(output_corrolation))) + "%\n")
print(max(stored_value))