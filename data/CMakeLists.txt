include(MMseqsResourceCompiler) 

set(COMPILED_RESOURCES
    downloaddb.sh
    annotate.sh
    assemblereads.sh
    createquerydb.sh
    easytransannot.sh
    )

set(GENERATED_OUTPUT_HEADERS "")
FOREACH(INPUT_FILE ${COMPILED_RESOURCES})
    compile_resource(${INPUT_FILE} OUTPUT_FILE)
    list(APPEND GENERATED_OUTPUT_HEADERS "${OUTPUT_FILE}")
ENDFOREACH()

add_custom_target(transannot-local-generated ALL DEPENDS ${GENERATED_OUTPUT_HEADERS}) 