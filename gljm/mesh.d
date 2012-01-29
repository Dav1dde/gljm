module gljm.mesh;

private {
    import derelict.opengl.gl : GLint, GLsizei, GLuint, GLenum,
                                glDrawElements, glDrawArrays,
                                GL_TRIANGLES, GL_UNSIGNED_SHORT;
    import std.typecons : Tuple;
    import gljm.util : glenum2size;
    import gljm.vbo : Buffer, ElementBuffer;
    import std.conv;
    
    debug {
        import std.stdio : writefln;
    }
}

alias Tuple!(int, "size", int, "offset") BufInfo;

struct Mesh {
    struct BufferS {
        alias Tuple!(BufInfo[string], Buffer) SBuf;
        private SBuf[] members;
        private int count = 0;
    
        void set(string s, Buffer b) {
            set([s : BufInfo(b.size, 0)], b);
        }
        void set(BufInfo[string] s, Buffer b) {
            members ~= SBuf(s, b);
            
            if(count == 0) {
                int size = 0;
                foreach(BufInfo bi; s.values) {
                    size += bi.size;
                }
                
                if(size) {
                    count = (to!(int)(b.length) / glenum2size(b.type)) / size;
                }
            }
        }

        void bind(GLuint[string] attrib_locations) {
            foreach(SBuf s; members) {
                Buffer buf = s[1];
                foreach(string loc, BufInfo bi; s[0]) {
                    if(loc in attrib_locations) {
                        buf.bind(attrib_locations[loc], bi.size, bi.offset);
                    } else {                                     
                        debug { writefln("bind buffer: no matching buffer for key \"" ~ loc ~ "\"."); }
                    }
                }
            }
        }
        
        void unbind() {
            foreach(SBuf s; members) {
                s[1].unbind();
            }
        }
    }
    
    ElementBuffer indices;
    BufferS buffer;
    
    @property int count() {
        if(indices) { return to!(int)(indices.length) / glenum2size(indices.type); }
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
        buffer.unbind();
    }
}