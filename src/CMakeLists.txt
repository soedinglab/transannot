include_directories(commons)
add_subdirectory(commons)
add_subdirectory(util)
add_subdirectory(workflow)

add_executable(annotate
    ${commons_source_files}
    ${util_source_files}
    ${workflow_source_files}
    LocalCommandDeclarations.h
    #annotate.cpp - will write this file later
    )
mmseqs_setup_derived_targets(annotate)
#target_link_libraries(annotate version)

add_dependencies(annotate local-generated)

install(TARGETS annotate DESTINATION bin)