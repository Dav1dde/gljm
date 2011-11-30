module gljm.mesh;

private {
    import derelict.opengl.gl : GLint, GLsizei, GLuint, GLenum,
                                glDrawElements, glDrawArrays,
                                GL_TRIANGLES, GL_UNSIGNED_SHORT;
    import gljm.util : glenum2size;
    import gljm.vbo : Buffer, ElementBuffer, BufferData;
    
    debug {
        import std.stdio : writefln;
    }
}


struct Mesh {
    struct BufferS {
        private Buffer[string] _members;
        private int count = 0;
        alias _members this;
    
        Buffer opDispatch(string s)() { return get(s); }
        Buffer get(string s) { return _members[s]; }
        /*package*/ void set(string s, Buffer b) {
            _members[s] = b;
            
            if(!count) {
                count = (b.data.length / glenum2size(b.type)) / b.size;
            }
        }

        void bind(GLuint[string] attrib_locations) {
            foreach(string key, Buffer value; _members) {
                if(key in attrib_locations) {
                    value.bind(attrib_locations[key]);
                }
                
                debug {
                    if(key !in attrib_locations) {
                        writefln("bind buffer: no matching buffer for key \"" ~ key ~ "\"."); 
                    }
                }
            }
        }
        
        void unbind() {
            foreach(string key, Buffer value; _members) {
                value.unbind();
            }
        }
        void unbind(GLuint[string] attrib_locations) {
            foreach(string key, Buffer value; _members) {
                if(key in attrib_locations) {
                    value.unbind(attrib_locations[key]);
                }
                
                debug {
                    if(key !in attrib_locations) {
                        writefln("unbind buffer: no matching buffer for key \"" ~ key ~ "\"."); 
                    }
                }
            }
        }
        
    }
    
    ElementBuffer indices;
    BufferS buffer;
    
    @property int count() {
        if(indices) { return indices.data.length / glenum2size(indices.type); }
        else { return buffer.count; }
    }
    
    void draw(GLuint[string] attrib_locations, GLenum mode = GL_TRIANGLES, GLint offset = 0, GLsizei count_ = -1) {
        buffer.bind(attrib_locations);
        
        int c = count_ < 0 ? count:count_;
        if(indices) {
            indices.bind();

            glDrawElements(mode, c, indices.type, cast(void *)(offset));
            indices.unbind();
        } else {
            glDrawArrays(mode, offset, c);
        }
        buffer.unbind(attrib_locations);
    }
}