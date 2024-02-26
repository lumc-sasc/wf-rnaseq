def YML_READ(samples) {
    // A read list is made. 
    read_list = []

    //each sample will be read
    samples.each {sample -> sample.libraries.each {

        //each readpair will be read
        library -> library.readgroups.reads.each {
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
    return Channel.fromList(read_list)
}