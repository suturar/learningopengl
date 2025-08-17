#import "Basic";
#import "Window_Creation";
#import "Math";
#import "GL";
#import "Input";
#import "X11";
#load "common.jai";

vertex_shader_code :: #string DONE
#version 330 core

layout (location = 0) in vec3 pos;

uniform float h_offset;

out vec3 vertex_color;

void main()
{
    gl_Position = vec4(h_offset + pos.x, -pos.y, pos.z, 1.0f);
    vertex_color = pos.xyz;
}
DONE

fragment_shader_code :: #string DONE
#version 330 core

out vec4 frag_color;
in vec3 vertex_color;

void main() {
    // vec3 a = vertex_color;
    frag_color = vec4(vertex_color, 1.0f);
}
DONE

main :: () {

    window := create_window(800, 800, #run basename(#file));
    gl_create_context(window, 3, 3);
    gl_load(*gl);

    vertices: []float = .[
        -0.5, -0.5, 0.0,
         0.5, -0.5, 0.0,
         0.0,  0.5, 0.0,
    ];

    glViewport(0, 0, 800, 800);

    vertex_shader, ok := compile_shader(vertex_shader_code, GL_VERTEX_SHADER, "vertex shader");
    if !ok exit(1);
    defer glDeleteShader(vertex_shader);

    fragment_shader :, ok= compile_shader(fragment_shader_code, GL_FRAGMENT_SHADER, "fragment shader");
    if !ok exit(1);
    defer glDeleteShader(fragment_shader);

    shader_program :, ok = link_program(vertex_shader, fragment_shader);
    if !ok exit(1);
    defer glDeleteProgram(shader_program);

    h_offset_loc := get_uniform_location(shader_program, "h_offset");

    VBO, VAO: GLsizei;
    glGenVertexArrays(1, *VAO);
    glGenBuffers(1, *VBO);

    glBindVertexArray(VAO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, size_of(type_of(vertices[0])) * vertices.count, vertices.data, GL_STATIC_DRAW);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * size_of(float), null);
    glEnableVertexAttribArray(0);

    quit := false;
    while !quit {
        update_window_events();
        reset_temporary_storage();
        for events_this_frame {
            if it.type == {
                case .QUIT;
                    quit = true;
                case.KEYBOARD;
                    if it.key_code == {
                        case #char "Q"; #through;
                        case .ESCAPE;
                            quit = true;
                    }
            }
        }

        glClearColor(0x18/255.0, 0x18/255.0, 0x18/255.0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);

        glUseProgram(shader_program);
        h_offset := sin(get_seconds_since_startup()) / 2;
        glUniform1f(h_offset_loc, h_offset);
        glBindVertexArray(VAO);
        glDrawArrays(GL_TRIANGLES, 0, xx vertices.count);
        glXSwapBuffers(x_global_display, window);
    }
}
