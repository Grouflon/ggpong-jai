AT_COMPILE_TIME :: true;

#if AT_COMPILE_TIME {
    #run,stallable {
        set_build_options_dc(.{do_output=false});
        root_options := get_build_options();
        args := root_options.compile_time_command_line;
        if !generate_bindings(args) {
            compiler_set_workspace_status(.FAILED);
        }
    }
} else {
    #import "System";

    main :: () {
        set_working_directory(path_strip_filename(get_path_of_running_executable()));
        args := get_command_line_arguments();
        if !generate_bindings(args) {
            exit(1);
        }
    }
}

generate_bindings :: (args: [] string) -> bool
{
    output_filename: string;
    opts: Generate_Bindings_Options;
    {
        using opts;

        target_wasm: = false;
        if array_find(args, "-wasm") target_wasm = true;

        if target_wasm
        {
            array_add(*libpaths, "wasm");
            output_filename = "wasm.jai";
            opts.static_library_suffix = ".a";
        }
        else
        {
            #if OS == .WINDOWS {
            array_add(*libpaths, "windows");
            output_filename = "windows.jai";
            } else {
                assert(false);
            }
        }

        array_add(*libnames, "GGPO");
        array_add(*include_paths, "ggpo/src/include");
        array_add(*source_files, "ggpo/src/include/ggponet.h");
        array_add(*extra_clang_arguments, "-x", "c++", "-DWIN32_LEAN_AND_MEAN");

        auto_detect_enum_prefixes = false;
        log_stripped_declarations = false;
        generate_compile_time_struct_checks = false;

        visitor   = raylib_visitor;
    }

    return generate_bindings(opts, output_filename);
}

DECLARATIONS_TO_OMIT :: string.[
];

raylib_visitor :: (decl: *Declaration, parent_decl: *Declaration) -> Declaration_Visit_Result
{
    if !parent_decl
    {
        if array_find(DECLARATIONS_TO_OMIT, decl.name)
        {
            decl.decl_flags |= .OMIT_FROM_OUTPUT;
            return .STOP;
        }
    }

    return .RECURSE;
}

#import "Basic";
#import "Bindings_Generator";
#import "Compiler";
#import "String";
