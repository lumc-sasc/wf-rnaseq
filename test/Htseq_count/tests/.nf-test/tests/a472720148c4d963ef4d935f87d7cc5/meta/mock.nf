import groovy.json.JsonGenerator
import groovy.json.JsonGenerator.Converter

nextflow.enable.dsl=2

// comes from nf-test to store json files
params.nf_test_output  = ""

// include dependencies


// include test process
include { COLLECT_COLUMN } from '/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/test/Htseq_count/tests/../../../custom_modules/collect_column/main.nf'

// define custom rules for JSON that will be generated.
def jsonOutput =
    new JsonGenerator.Options()
        .excludeNulls()  // Do not include fields with value null..
        .addConverter(Path) { value -> value.toAbsolutePath().toString() } // Custom converter for Path. Only filename
        .build()


workflow {

    // run dependencies
    

    // process mapping
    def input = []
    
                input[0] = Channel.of([
                    [id: "test"],
                    ["/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/work/98/276a772a699b65414cee689d5bdb12/s105858-001-010.txt", 
                     "/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/work/1e/8cacff0f26a052fbaace9484ad451d/s105858-001-020.txt",
                     "/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/work/66/e19c01395c37699f010b3a8899409b/s105858-001-001.txt",
                     "/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/work/6e/013bdf9a2ddddf62b07b9bb95f61d3/s105858-001-021.txt",
                     "/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/work/7c/0479db4bd5e933c5ba06c608e31d05/s105858-001-022.txt",
                     "/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/work/d8/df8f561f5587bd42fc88ce209e8c39/s105858-001-002.txt",
                     "/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/work/7c/ccc17fbc7420d40e6517b1ff5f1be3/s105858-001-006.txt",
                     "/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/work/6f/5a2988e94970e783b3b0986a75a461/s105858-001-025.txt",
                     "/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/work/0c/d8dbf3081eb32d6e3456a235635872/s105858-001-018.txt",
                     "/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/work/81/c39361a8eb15dfc15509b28c4a9b82/s105858-001-029.txt",
                     "/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/work/64/776a15081f83758239e8a23279b6d9/s105858-001-017.txt",
                     "/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/work/57/2f3880b548975aed79f7d98ab9e6ca/s105858-001-026.txt",
                     "/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/work/59/2b2ea963844c6edf9658ebfdaaccf6/s105858-001-005.txt",
                     "/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/work/1f/8479df992eac0c5b0098a130e5834f/s105858-001-019.txt",
                     "/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/work/ff/383fce8005ba5cce85c148c160c915/s105858-001-011.txt",
                     "/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/work/19/2fddd86fcea0592043a0fa0ef74a9b/s105858-001-003.txt",
                     "/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/work/57/852e23a255bbed10b7f03bdb6db616/s105858-001-030.txt",
                     "/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/work/cc/a9d1d2de37324e4dc6a683bea6198e/s105858-001-027.txt",
                     "/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/work/ac/464e2a8bc902d634d87133ba7b8951/s105858-001-013.txt",
                     "/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/work/22/0de8df8e808d3388b6f9b453391c5d/s105858-001-012.txt",
                     "/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/work/89/3c6ec9a68639330aee86e5c27ab5da/s105858-001-028.txt",
                     "/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/work/cf/ee41212e28c3354889f9ce7d7815bd/s105858-001-004.txt",
                     "/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/work/6a/01673d2d15ffd8737e1cdc130eb1bc/s105858-001-009.txt",
                     "/exports/sascstudent/vperinbanathan/nextflow_pipeline_testzone/work/de/81195730f3eaf6103ddce6d8be364a/s105858-001-014.txt"]])

                input[1] = [[id:"test"],"/exports/sascstudent/vperinbanathan/Genomes/Homo_sapiens/GRCh38/Homo_sapiens.GRCh38.110.gtf"]

                input[2] = 000
                
    //----

    //run process
    COLLECT_COLUMN(*input)

    if (COLLECT_COLUMN.output){

        // consumes all named output channels and stores items in a json file
        for (def name in COLLECT_COLUMN.out.getNames()) {
            serializeChannel(name, COLLECT_COLUMN.out.getProperty(name), jsonOutput)
        }	  
      
        // consumes all unnamed output channels and stores items in a json file
        def array = COLLECT_COLUMN.out as Object[]
        for (def i = 0; i < array.length ; i++) {
            serializeChannel(i, array[i], jsonOutput)
        }    	

    }
  
}

def serializeChannel(name, channel, jsonOutput) {
    def _name = name
    def list = [ ]
    channel.subscribe(
        onNext: {
            list.add(it)
        },
        onComplete: {
              def map = new HashMap()
              map[_name] = list
              def filename = "${params.nf_test_output}/output_${_name}.json"
              new File(filename).text = jsonOutput.toJson(map)		  		
        } 
    )
}


workflow.onComplete {

    def result = [
        success: workflow.success,
        exitStatus: workflow.exitStatus,
        errorMessage: workflow.errorMessage,
        errorReport: workflow.errorReport
    ]
    new File("${params.nf_test_output}/workflow.json").text = jsonOutput.toJson(result)
    
}
