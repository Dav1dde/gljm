module gljm.parser.json;

private {
    import gljm.mesh : Mesh;
    import gljm.vbo : ElementBuffer, Buffer, BufferData;
    import gljm.util : conv_array;
    import libdjson.json : JSONType, JSONObject, readJSON;
    import derelict.opengl.gl : GLint, GL_FLOAT, GL_UNSIGNED_SHORT, GL_INT;
    import std.file : readText;
    import std.array : split;
    import std.conv : to;
}

Mesh load_json_mesh(JSONObject jobj) {
    Mesh m;
    
    foreach(string key, JSONType value; jobj) {
        auto arr = split(key, "_");
        
        if(arr.length == 1) {
            if(!m.indices) {
                string name = key;
                
                ushort[] data;
                foreach(JSONType num; value) {
                    if(num.toJSONNumber !is null) {
                        data ~= to!(ushort)(num.toJSONNumber.get());
                    } else {
                        throw new Exception("unable to parse json, error occurred when processing key \"" ~ key ~ "\", "
                                            "can not convert \"" ~ num.toString ~ "\" to ushort.");
                    }
                }
                ElementBuffer buffer = ElementBuffer();
                buffer.set_data(data, GL_UNSIGNED_SHORT);
            
                m.indices = buffer;
            } else {
                throw new Exception("only one index buffer is allowed per mesh.");
            }
        } else if((arr.length == 2) && (arr[1].length == 2)) {
            string name = arr[0];
            GLint size = to!(GLint)(arr[1][0..1]); // for correct conversion, we need a string => slice
            char ctype = arr[1][1];
            
            real[] data;
            foreach(JSONType num; value) {
                if(num.toJSONNumber !is null) {
                    data ~= num.toJSONNumber.get();
                } else {
                    throw new Exception("unable to parse json, error occurred when processing key \"" ~ key ~ "\", "
                                        "can not convert \"" ~ num.toString ~ "\" to real.");
                }
            }
            
            BufferData buffer_data;
            switch(ctype) {
                case 'f': buffer_data = BufferData(conv_array!(float)(data), GL_FLOAT, size); break;
                case 's': buffer_data = BufferData(conv_array!(ushort)(data), GL_UNSIGNED_SHORT, size); break;
                case 'i': buffer_data = BufferData(conv_array!(int)(data), GL_INT, size); break;
                default: throw new Exception("key \"" ~ key ~ "\" has unknown type \"" ~ ctype ~ "\", "
                                             "only f, s and i are supported.");
            }
            
            Buffer buffer = Buffer();
            buffer.buffer_data = buffer_data;
                        
            m.buffer.set(name, buffer);
        } else {
            throw new Exception("malformed key: \"" ~ key ~ "\".");
        }
    }
    
    return m;
}

Mesh load_json_mesh(string jstring) {
    return load_json_mesh(readJSON(jstring).toJSONObject);
}

Mesh load_json_mesh_from_file(string path) {
    return load_json_mesh(readText(path));
}