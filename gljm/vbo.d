module gljm.vbo;

private {
    import gljm.util : type2glenum;
    import derelict.opengl.gl;
}


struct Buffer(type, GLenum gltype) {
    alias type bt;
    alias type2glenum!type glbt;
    
    
    bt[] _data;
    GLuint buffer;
    
    
    @disable this();
    
    static Buffer opCall() {
        return Buffer(0);
    }
    
    package this(ubyte x) { // dirty, but it works
        glGenBuffers(1, &buffer);
    }
    
    this(bt[] data_) {
        glGenBuffers(1, &buffer);
        set_data(data_);
    }

    this(bt[] data_, GLenum hint) {
        glGenBuffers(1, &buffer);
        set_data(data_, hint);
    }
        
    void bind() {
        glBindBuffer(gltype, buffer);
    }
    
    static if (gltype == GL_ARRAY_BUFFER) {
        void bind(GLuint attrib_location, GLint size) {
            glBindBuffer(gltype, buffer);
            glEnableVertexAttribArray(attrib_location);
            glVertexAttribPointer(attrib_location, size, glbt, false, 0, 0);
        }
    }
    
    void unbind() {
        glBindBuffer(gltype, 0);
    }
    
    void set_data(bt[] data_, GLenum hint = GL_STATIC_DRAW) {
        glBindBuffer(gltype, buffer); // or bind()
        glBufferData(gltype, (bt.sizeof * data_.length), data_.ptr, hint);
        _data = data_;
        glBindBuffer(gltype, 0); //or unbind()
    }
    
    @property void data(bt[] data) {
        set_data(data);
    }
    
    @property bt[] data() {
        return _data;
    }
    
}