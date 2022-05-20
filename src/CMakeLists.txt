include_directories(commons)
add_subdirectory(commons)
add_subdirectory(util)
add_subdirectory(version)
add_subdirectory(workflow)

add_executable(transannot
        ${commons_source_files}
        ${workflow_source_files}
        ${util_source_files}
        LocalCommandDeclarations.h
        transannot.cpp 
        )
mmseqs_setup_derived_target(transannot)
target_link_libraries(transannot version)

add_dependencies(transannot transannot-local-generated)

install(TARGETS transannot DESTINATION bin)
