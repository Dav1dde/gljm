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
    struct BufferS {
        private Buffer[string] _members;
        private int count = 0;
        alias _members this;
    
        Buffer opDispatch(string s)() { return get(s); }
        Buffer get(string s) { return _members[s]; }
        package void set(string s, Buffer b) {
            _members[s] = b;
            
            if(!count) {
                count = b.data.length / b.size;
            }
        }

        void bind(GLuint[string] attrib_locations) {
            foreach(string key, Buffer value; _members) {
                if(key in attrib_locations) {
                    value.bind(attrib_locations[key]);
                }
            }
        }
        
        void unbind() {
            foreach(string key, Buffer value; _members) {
                value.unbind();
            }
        }
        
    }
    
    ElementBuffer indices;
    BufferS buffer;
    
    @property int count() {
        if(indices) { return indices.data.length; }
        else { return buffer.count; }
    }
    
    void draw(GLuint[string] attrib_locations, GLenum mode = GL_TRIANGLES, GLint offset = 0, GLsizei count_ = -1) {
        buffer.bind(attrib_locations);
        if(indices) {
            indices.bind();
            
            glDrawElements(mode, (count_<0?indices.data.length:count_), GL_UNSIGNED_SHORT, cast(void *)(offset));
            indices.unbind();
        } else {
            glDrawArrays(mode, offset, (count_<0?buffer.count:count_));
        }
        buffer.unbind();
    }
}

Mesh load_mesh(JSONObject jobj) {
    Mesh m;
    
    foreach(string key, JSONType value; jobj) {
        auto arr = split(key, "_");

        if(arr.length == 1) {
            if(!m.indices) {
                string name = key;
                
                ushort[] data;
                foreach(JSONType num; value) {
                    data ~= to!(ushort)(num.toJSONNumber.getLong());
                }
                
                ElementBuffer buffer = ElementBuffer();
                buffer.set_data(data);
            
                m.indices = buffer;
            } else {
                throw new Exception("Just one indices buffer allowed per mesh");
            }
        } else if(arr.length == 2) {
            string name = arr[0];
            GLint size = to!(GLint)(arr[1][0..1]); // for correct conversion, we need a string => slice
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

