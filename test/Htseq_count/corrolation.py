import sys

#Grabbing paths from nf-test bash command.
reference_file_path = sys.argv[1]
nextflow_file_path = sys.argv[2]


#reforming data of reference so it can be used for corrolation
with open(reference_file_path, "r") as reference_file:
    #creating the headers and sort the headers based on the sample name.
    header = reference_file.readline().strip("\n").split("\t")
    sorted_header = sorted(header)

    #Create list to add all lines to
    count_lines_reference = []

    #Create an index list that keeps track of the original positions of the sorted headers.
    index_list = []
    #Calling indexes and stores it in the index list
    for head in sorted_header:
        index_list.append(header.index(head))

    #Go through lines of file and add them based on the index
    for lines in reference_file:

        #Create count list for single line
        count_line = []

        #Splitting the line into a list so it can be sorted according to index list
        line = lines.strip("\n").split("\t")

        #Looping through index_list to sort everything
        for index in index_list:
            count_line.append(line[index])
        count_lines_reference.append(count_line)




#Reforming data of Nextflow so it can be used for corrolation
with open(nextflow_file_path, "r") as reference_file:
    #creating the headers and sort the headers based on the sample name.
    header = reference_file.readline().strip("\n").split("\t")
    sorted_header = sorted(header)

    #Create list to add all lines to
    count_lines_nextflow = []

    #Create an index list that keeps track of the original positions of the sorted headers.
    index_list = []
    #Calling indexes and stores it in the index list
    for head in sorted_header:
        index_list.append(header.index(head))

    #Go through lines of file and add them based on the index
    for lines in reference_file:

        #Create count list for single line
        count_line = []

        #Splitting the line into a list so it can be sorted according to index list
        line = lines.strip("\n").split("\t")

        #Looping through index_list to sort everything
        for index in index_list:
            count_line.append(line[index])
        count_lines_nextflow.append(count_line)

        

#Start of corrolation calculation
Reference_lines = len(count_lines_reference) - 1
Nextflow_lines = len(count_lines_nextflow) - 1
corrolation = 0
line_count = Reference_lines + 1

while Reference_lines != 0 and Nextflow_lines !=0:
    Reference_instance = count_lines_reference[Reference_lines]
    Nextflow_instance = count_lines_nextflow[Nextflow_lines]
    if Reference_instance[0] == Nextflow_instance[0]:
        corrolation_line = 0
        for reference_count, nextflow_count in zip(Reference_instance[1:], Nextflow_instance[1:]):
            if float(reference_count) == float(nextflow_count):
                corrolation_line += 1
        
        corrolation += corrolation_line / len(Reference_instance[1:])
        del count_lines_reference[Reference_lines]
        del count_lines_nextflow[Nextflow_lines]
        Reference_lines -= 1
        Nextflow_lines -= 1
    
    elif Reference_lines > Nextflow_lines:
        del count_lines_reference[Reference_lines]
        Reference_lines -= 1
    
    elif Nextflow_lines > Reference_lines:
        del count_lines_nextflow[Nextflow_lines]
        Nextflow_lines -= 1
    
    else:
        del count_lines_reference[Reference_lines]
        Reference_lines -= 1
        del count_lines_nextflow[Nextflow_lines]
        Nextflow_lines -= 1

output_corrolation = corrolation/line_count * 100
sys.stdout.write(str(output_corrolation))
sys.exit(0)