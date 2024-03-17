class Testing {
    public static Object corrolation_check(file) {
        //WDL INITIALIZING
        def wdl_file_list = []
        def wdl_file = path("/exports/sascstudent/vperinbanathan/WDL_RNA/output/expression_measures/fragments_per_gene/all_samples.fragments_per_gene").eachLine {
            wdl_file_list.add(it.split("\t"))
        }

        def header = []
        wdl_file_list[0].each { item ->
                header.add(item)
                }
        def sorted_header = wdl_file_list[0].sort()
        def WDL_lines = []
        def indexes = []
        sorted_header.each { column ->
            indexes.add(header.indexOf(column))
        }

        for (int i = 1; i < wdl_file_list.size(); i++) {
            def line = []
            for (part in indexes) {
                line.add(wdl_file_list[i][part])
            WDL_lines.add(line)

            }
        }
        def WDL_line = WDL_lines.size() -1

        //NEXTFLOW INITIALIZING
        def nextflow_file_list = []
        def nextflow_file = path(file).eachLine {
            nextflow_file_list.add(it.split("\t"))
        }
        header = []
        nextflow_file_list[0].each { item ->
        header.add(item)
        }
        sorted_header = nextflow_file_list[0].sort()
        def Nextflow_lines = []
        indexes = []
        sorted_header.each { column ->
            indexes.add(header.indexOf(column))
        }
        for (int i = 1; i < nextflow_file_list.size(); i++) {
            def line = []
            for (part in indexes) {
                line.add(nextflow_file_list[i][part])
            Nextflow_lines.add(line)

            }
        }
        def Nextflow_line = Nextflow_lines.size() -1

        def line_corrolation = 0
        def line_count = WDL_lines.size()

        while (0 < Nextflow_lines.size() && 0 < WDL_lines.size()) {
            def WDL_instance = WDL_lines[WDL_line]
            def Nextflow_instance = Nextflow_lines[Nextflow_line]
            if (WDL_instance[0] == Nextflow_instance[0]) {
                def corrolation = 0
                for (int i= 1; i < Nextflow_instance.size(); i++) {
                    if (Float.valueOf(WDL_instance[i]) == Float.valueOf(Nextflow_instance[i])) {
                        corrolation += 1
                    }
                }
                line_corrolation += corrolation / (WDL_instance.size() -1 )
                WDL_lines.remove(WDL_line)
                Nextflow_lines.remove(Nextflow_line)
                WDL_line -= 1
                Nextflow_line -= 1
            }

            else if(WDL_instance[0].trim("ENSG").toInteger() > Nextflow_instance[0].trim("ENSG").toInteger()) {
                    WDL_lines.remove(WDL_line)
                    WDL_line -= 1
            }

            else {
                Nextflow_lines.remove(Nextflow_line)
                Nextflow_line -= 1
            }
        }
        def output_corrolation = line_corrolation/line_count*100
        return output_corrolation
    }
}
