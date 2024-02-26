//loading in functions.
include {YML_READ as Yml_Read} from "../yml/main.nf"
include {CSV_READ as Csv_Read} from "../csv/main.nf"

//YAML package is imported. This is needed to load in yml files.
import org.yaml.snakeyaml.Yaml

//CSV package is imported. This is needed to load in csv files.
@Grab( 'com.xlson.groovycsv:groovycsv:1.0' )
import com.xlson.groovycsv.CsvParser

def FILE_CHECK() {
    //Samplesheet definition
    //grabs the file extension from the file path.
    filetype_check = params.sampleConfigFile.split("\\.").last()

    //checks if filetype is yml
    if (filetype_check == "yml") {
        //yaml to parse yaml samplesheet file.
        def yaml = new Yaml()
        read_list = Yml_Read(yaml.load(new FileInputStream(new File("$baseDir/${params.sampleConfigFile}"))).samples)
    }

    //checks if filetype is csv
    else if (filetype_check == "csv") {
        read_list = Csv_Read(CsvParser.parseCsv(file("$baseDir/${params.sampleConfigFile}", checkIfExists: true).text))
    }
    return read_list
}