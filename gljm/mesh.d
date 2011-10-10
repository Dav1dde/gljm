module gljm.mesh;

private {
    import std.file : readText;
    import libdjson.json : JSONType, JSONObject, readJSON;
    import std.array : split;
    import std.conv : to;
    import derelict.opengl.gl : GLint, GLsizei, GLuint, GLenum,
                                glDrawElements, glDrawArrays,
                                GL_TRIANGLES, GL_FLOAT, GL_UNSIGNED_SHORT, GL_INT;
    import gljm.util : conv_array;
    import gljm.vbo : Buffer, ElementBuffer, BufferData;
}


struct Mesh {
    struct ElementBufferS {
        private ElementBuffer[string] _members;
        private int count = 0;
        alias _members this;
    
        ElementBuffer opDispatch(string s)() { return get(s); }
        ElementBuffer get(string s) { return _members[s]; }
        package void set(string s, ElementBuffer b) {
            _members[s] = b;
            
            if(!count) {
                count = b.buffer_data.data.length;
            }
        }
        
        void bind() { // kinda strange, more then one ELEMENT_ARRAY_BUFFER?
            foreach(string key, ElementBuffer value; _members) {
                value.bind();
            }
        }
    }
    
    struct BufferS {
        private Buffer[string] _members;
        private int count = 0;
        alias _members this;
    
        Buffer opDispatch(string s)() { return get(s); }
        Buffer get(string s) { return _members[s]; }
        package void set(string s, Buffer b) {
            _members[s] = b;
            
            if(!count) {
                count = b.buffer_data.data.length / b.buffer_data.size;
            }
        }
        
//         void bind() { // you dont want this!
//             foreach(string key, Buffer value) {
//                 value.bind(); 
//             }
//         }
        
        void bind(GLuint[string] attrib_locations) {
            foreach(string key, Buffer value; _members) {
                value.bind(attrib_locations[key]);
            }
        }
    }
    
    ElementBufferS element_buffer;
    BufferS buffer;
    
    @property int count() {
        if(element_buffer) { return element_buffer.count; }
        else { return buffer.count; }
    }
    
    void draw(GLuint[string] attrib_locations, GLenum mode = GL_TRIANGLES, GLint offset = 0, GLsizei count_ = -1) {
        buffer.bind(attrib_locations);
        if(element_buffer) {
            element_buffer.bind();
            
            glDrawElements(mode, (count_<0?element_buffer.count:count_), GL_UNSIGNED_SHORT, cast(void *)(offset));
        } else {
            glDrawArrays(mode, offset, (count_<0?buffer.count:count_));
        }
    }
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

