include_directories(commons)
add_subdirectory(commons)
add_subdirectory(util)
#add_subdirectory(version) - later
add_subdirectory(workflow)

add_executable(transannot
    ${commons_source_files}
    ${util_source_files}
    ${workflow_source_files}
    LocalCommandDeclarations.h
    transannot.cpp 
    )
mmseqs_setup_derived_target(annotation_tool)
#target_link_libraries(annotate version)

add_dependencies(annotation_tool local-generated)

install(TARGETS annotation_tool DESTINATION bin)