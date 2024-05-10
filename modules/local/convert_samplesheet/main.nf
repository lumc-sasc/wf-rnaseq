//YAML package is imported. This is needed to load in yml files.
import org.yaml.snakeyaml.Yaml

process FILE_CHECK {
    input:
        path(sampleConfigFile)
        val(file_type)

    output:
        val(read_list), emit: read_list
    
    script:
        //checks if filetype is yml
        if (file_type == "yml") {
            //yaml to parse yaml samplesheet file.
            def yaml = new Yaml()
            samples = yaml.load(new FileInputStream(new File("$sampleConfigFile.target"))).samples
            read_list = []

            //each sample will be read
            samples.each {sample ->
            sample.libraries.each {

            //each readpair will be read
            library ->
            library.readgroups.reads.each {
                readgroup -> 

                    //reads will be stored in a variable. Read1 just gets read1 and read2 will only contain data if it is present.
                    //If not it is an empty string
                    read1 = readgroup.R1
                    read2 = readgroup.R2 ? readgroup.R2: ""
                    /* It will check if it is single_end. If read2 is not an empty string it will be added as a pair with
                    read1. Otherwise only read1 will be added to the nested list.*/
                    if (read2 != "") {
                        read_list << [[id: "${sample.id}_${library.id}", single_end: false, sample: "${sample.id}"],[file(read1, checkIfExists: true), file(read2, checkIfExists: true)]]
                    }
                    else {
                        read_list << [[id: "${sample.id}_${library.id}", single_end: true,  sample: "${sample.id}"],[file(read1, checkIfExists: true)]]
                    }
                }
            }
            }
        }

        //checks if filetype is csv
        else if (file_type == "csv") {
            samples = file("$sampleConfigFile.target").splitCsv(header: true, sep: ',')
            read_list = []
            samples.each{ information ->
                id = "${information.sample}_${information.lib}_${information.R1_md5}"
                sample = "${information.sample}"
                read1 = information.R1
                read2 = information.R2 != null ? information.R2 : ""

                if (read2 != "") {
                    read_list << [[id: id, single_end: false, sample: sample], [file(read1, checkIfExists: true), file(read2, checkIfExists: true)]]
                }
                else {
                    read_list << [[id : id, single_end: true, sample: sample], [file(read1, checkIfExists: true)]]
                }
            }
        }


    """
    """

}