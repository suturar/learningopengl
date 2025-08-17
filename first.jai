#import "Basic";
#import "Compiler";
#import "File_Utilities";
#import "File";

files_to_build : []string = .[
    "src/101_triangle.jai",
    "src/102_square.jai",
    "src/103_triangle_color_dance.jai",
    "src/104_triangle_rainbow.jai",
    "src/105_triangle_upside_down.jai",
    "src/106_square_texture.jai",
];

build :: () {
    build_options := get_build_options();
    set_build_options_dc(.{do_output = false});


    output_dir := tprint("%/out", #filepath);
    make_directory_if_it_does_not_exist(output_dir);
    build_options.output_path = output_dir;
    build_options.text_output_flags = xx 2;

    for files_to_build {
        basename, path := get_basename_and_path(it);
        print("INFO: Compiling '%'...\n", basename);
        w := compiler_create_workspace(basename);
        if !w {
            print("ERROR: Could not create workspace!\n");
            exit(1);
        }

        target_options := build_options;
        target_options.output_executable_name = basename;
        set_build_options(target_options, w);

        add_build_file(it, w);
    }
}
#run build();
