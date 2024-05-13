def CSV_READ(samples) {
    read_list = []
    samples.each{ instance ->
        id = "${instance.sample}_${instance.library}_${instance.R1_md5}"
        sample = "${instance.sample}"
        read1 = instance.R1
        read2 = instance.R2 != null ? instance.R2 : ""

        if (read2 != "") {
                read_list << [[id: id, single_end: false, sample: sample], [file(read1, checkIfExists: true), file(read2, checkIfExists: true)]]
            }
        else {
                read_list << [[id : id, single_end: true, sample: sample], [file(read1, checkIfExists: true)]]
            }
    }

    return Channel.fromList(read_list)

}