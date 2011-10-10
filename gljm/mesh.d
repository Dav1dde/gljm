module gljm.mesh;

private {
    import std.file : readText;
    import libdjson.json : JSONType, JSONObject, readJSON;
    import std.array : split;
    import std.conv : to;
    import derelict.opengl.gl : GLint, GL_FLOAT, GL_UNSIGNED_SHORT, GL_INT;
    import gljm.util : conv_array;
    import gljm.vbo : Buffer, ElementBuffer, BufferData;
}


struct Mesh {
    struct ElementBufferS {
        private ElementBuffer[string] _members;
        alias _members this;
    
        ElementBuffer opDispatch(string s)() { return get(s); }
        package void set(string s, ElementBuffer b) { _members[s] = b; }
        ElementBuffer get(string s) { return _members[s]; }
    }
    
    struct BufferS {
        private Buffer[string] _members;
        alias _members this;
    
        Buffer opDispatch(string s)() { return get(s); }
        package void set(string s, Buffer b) { _members[s] = b; }
        Buffer get(string s) { return _members[s]; }
    }
    
    ElementBufferS element_buffer;
    BufferS buffer;
}


Mesh load_mesh(JSONObject jobj) {
    Mesh m;
    
    foreach(string key, JSONType value; jobj) {
        auto arr = split(key, "_");

        if(arr.length == 1) {
            string name = key;
            
            ushort[] data;
            foreach(JSONType num; value) {
                data ~= to!(ushort)(num.toJSONNumber.getLong());
            }
            
            ElementBuffer buffer = ElementBuffer();
            buffer.set_data(data);
            
            m.element_buffer.set(name, buffer);
        } else if(arr.length == 2) {
            string name = arr[0];
            GLint size = to!(GLint)(arr[1][0]);
            char ctype = arr[1][1];
            
            real[] data;
            foreach(JSONType num; value) {
                data ~= num.toJSONNumber.get();
            }
            
            BufferData buffer_data;
            switch(ctype) {
                case 'f': buffer_data = BufferData(conv_array!(float)(data), GL_FLOAT, size); break;
                case 's': buffer_data = BufferData(conv_array!(ushort)(data), GL_UNSIGNED_SHORT, size); break;
                case 'i': buffer_data = BufferData(conv_array!(int)(data), GL_INT, size); break;
                default: throw new Exception("key \"" ~ key ~ "\" has unknown type \"" ~ ctype ~ "\","
                                             "just f, s and i supported");
            }
            
            Buffer buffer = Buffer();
            buffer.buffer_data = buffer_data;
                        
            m.buffer.set(name, buffer);
        } else {
            throw new Exception("malformed key: " ~ key);
        }
    }
    
    return m;
}

Mesh load_mesh(string jstring) {
    return load_mesh(readJSON(jstring).toJSONObject);
}

Mesh load_mesh_from_file(string path) {
    return load_mesh(readText(path));
}

