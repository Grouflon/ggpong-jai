#run build();

BUILD_NAME :: "ggpong";
BUILD_OUTPUT_DIRECTORY :: "bin";

copy_file_if_newer :: (source_path: string, destination_path: string) -> (copied: bool)
{
    source_modtime, source_size, source_exists: = file_modtime_and_size(source_path);
    destination_modtime, destination_size, destination_exists: = file_modtime_and_size(destination_path);
    if !source_exists
        return false;

    if destination_exists && destination_modtime >= source_modtime
        return false;

    copy_file(source_path, destination_path);
    return true;
}

build :: ()
{
    // Read arguments
    args := get_build_options().compile_time_command_line;

    debug := array_find(args, "debug");
    run := array_find(args, "run");

    // Make bin directory
   	make_directory_if_it_does_not_exist(BUILD_OUTPUT_DIRECTORY, recursive = true);

   	// Copy raylib dll
    source_dll_path: = "modules/raylib/windows/raylib.dll"; 
   	target_dll_path: = tprint("%/raylib.dll", BUILD_OUTPUT_DIRECTORY);
    if copy_file_if_newer(source_dll_path, target_dll_path)
        log(tprint("Copied % -> %", source_dll_path, target_dll_path));

    source_pdb_path: = "modules/raylib/windows/raylib.pdb";
    target_pdb_path: = tprint("%/raylib.pdb", BUILD_OUTPUT_DIRECTORY);
    if copy_file_if_newer(source_pdb_path, target_pdb_path)
        log(tprint("Copied % -> %", source_pdb_path, target_pdb_path));

   	// Compile
    w := compiler_create_workspace(BUILD_NAME);
    
    options := get_build_options();
    options.output_path = BUILD_OUTPUT_DIRECTORY;
    options.output_executable_name = BUILD_NAME;
    options.use_natvis_compatible_types = true;
    if debug
    {
        set_optimization(*options, .DEBUG);
    }
    set_build_options(options, w);
    
    error_count: = 0;
    compiler_begin_intercept(w);
    add_build_file("src/main.jai", w);
    while true
    {
        message: = compiler_wait_for_message();
        if message.kind == {
            case .ERROR; error_count += 1;
            case .COMPLETE; break;
        }
    }
    compiler_end_intercept(w);
    if error_count != 0
    {
        log(tprint("Compilation failed with % error% :@", error_count, ifx error_count > 1 then "s" else ""));
        return;
    }
    log("Compilation completed without error :)");

    // No executable for this workspace.
    set_build_options_dc(.{do_output=false});

    if run
    {
        exe_path: = tprint("%/%.exe", BUILD_OUTPUT_DIRECTORY, BUILD_NAME);
        cmd: []string = .[
            exe_path,
            "-p1"
        ];
        if debug
        {
            debug_cmd: [..]string;
            array_add(*debug_cmd, "remedybg", "-g", "-q");
            array_add(*debug_cmd, tprint("%.rdbg", BUILD_NAME));
            result, output_string: = run_command(..debug_cmd, capture_and_return_output= true);
            print("\n");
            log(output_string);
        }
        else
        {
            // Run executable
            result, output_string: = run_command(..cmd, capture_and_return_output= true);
            print("\n");
            log(output_string);
        }
    }
}

#import "Basic";
#import "File";
#import "File_Utilities";
#import "Compiler";
#import "Process";
