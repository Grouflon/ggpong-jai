#run build();

build_output_directory :: "bin";

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
    // Make bin directory
   	make_directory_if_it_does_not_exist(build_output_directory, recursive = true);

   	// Copy raylib dll
    source_dll_path: = "modules/raylib/windows/raylib.dll"; 
   	target_dll_path: = tprint("%/raylib.dll", build_output_directory);
    if copy_file_if_newer(source_dll_path, target_dll_path)
        log(tprint("copied % -> %", source_dll_path, target_dll_path));

    source_pdb_path: = "modules/raylib/windows/raylib.pdb";
    target_pdb_path: = tprint("%/raylib.pdb", build_output_directory);
    if copy_file_if_newer(source_pdb_path, target_pdb_path)
        log(tprint("copied % -> %", source_pdb_path, target_pdb_path));

   	// Compile
    w := compiler_create_workspace();
    
    options := get_build_options();
    options.output_path = build_output_directory;
    options.output_executable_name = "hadal";
    options.use_natvis_compatible_types = true;
    set_optimization(*options, .DEBUG);
    set_build_options(options, w);
    add_build_file("src/main.jai", w);

    // No executable for this workspace.
   	set_build_options_dc(.{do_output=false});
}

#import "Basic";
#import "File";
#import "File_Utilities";
#import "Compiler";