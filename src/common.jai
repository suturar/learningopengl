#import "String";
#import "stb_image";

default_vertex_shader_code :: #string DONE
#version 330 core
layout (location = 0) in vec3 pos;

void main()
{
    gl_Position = vec4(pos.x, pos.y, pos.z, 1.0f);
}
DONE

default_fragment_shader_code :: #string DONE
#version 330 core
out vec4 frag_color;

void main() {
    frag_color = vec4(1.0f, 0.5f, 0.2f, 1.0f);
}
DONE

apollo_time_at_startup := APOLLO_TIME_INVALID;
get_seconds_since_startup :: () -> float {
    if apollo_time_at_startup == APOLLO_TIME_INVALID {
        apollo_time_at_startup = current_time_monotonic();
    }
    current_time := current_time_monotonic();
    t : float = xx to_milliseconds(current_time - apollo_time_at_startup) / 1000.0;
    return t;
}

get_uniform_location :: (program: GLuint, name: string) -> GLint, bool {
    loc := glGetUniformLocation(program, tprint("%\0", name).data);
    if loc == -1 {
        print("ERROR: Could not locate uniform '%' in program [%]!\n", name, program);
        return 0, false;
    }
    return loc, true;
}


compile_shader :: (src: string, type: GLenum, tag: string = "") -> GLuint, bool {
    shader := glCreateShader(type);
    length := cast(s32, src.count);
    glShaderSource(shader, 1, *src.data, *length);
    glCompileShader(shader);
    status: GLint;
    glGetShaderiv(shader, GL_COMPILE_STATUS, *status);
    if xx status != GL_TRUE {
        log_length : GLsizei;
        message_buff : [1024]GLchar;
        glGetShaderInfoLog(shader, 1024, *log_length, message_buff.data);
        message : string;
        message.data = message_buff.data;
        message.count = log_length;
        print("ERROR: Couldn't compile shader [%] tagged by '%' due to:\n%\n", shader, tag, message);
        return 0, false;
    }
    print("INFO: Succesfully compiled shader [%] tagged by '%'.\n", shader, tag);
    return shader, true;
}

link_program :: (shaders: .. GLuint, tag: string = "") -> GLuint, bool {
    program := glCreateProgram();
    for shaders glAttachShader(program, it);
    glLinkProgram(program);
    status : GLint;
    glGetProgramiv(program, GL_LINK_STATUS, *status);
    if xx status != GL_TRUE {
        log_length : GLsizei;
        message_buff : [1024]GLchar;
        glGetProgramInfoLog(program, 1024, *log_length, message_buff.data);
        message : string;
        message.data = message_buff.data;
        message.count = log_length;
        print("ERROR: Couldn't link program [%] tagged by '%' due to: \n", program, tag, message);
        return 0, false;
    }
    print("INFO: Succesfully linked program [%] tagged by '%'.\n", program, tag);
    return program, true;
}

// stb_image wrappers
load_texture_from_file :: (filename: string) -> GLuint, bool{
    size: [2]s32;
    n_channels: s32;
    data := stbi_load(tprint("%\0", filename).data, *size[0], *size[1], *n_channels, 0);
    if data == null {
        print("ERROR: Could not load image from file '%'\n", filename);
        return 0, false;
    }
    texture : GLuint;
    glGenTextures(1, *texture);
    glBindTexture(GL_TEXTURE_2D, texture);

    glTextureParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTextureParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTextureParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTextureParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, xx size[0], xx size[1], 0, GL_RGB, GL_UNSIGNED_BYTE, data);
    glGenerateMipmap(GL_TEXTURE_2D);
    print("INFO: Loaded texture [%] from file '%'\n", texture, filename);
    return texture, true;
}
