module gljm.vbo;

private {
    import derelict.opengl.gl : GLenum, GLint, GLsizei, GLuint, GL_FALSE, glDisableVertexAttribArray,
                                glEnableVertexAttribArray, glVertexAttribPointer, 
                                GL_STATIC_DRAW, GL_ARRAY_BUFFER, GL_ELEMENT_ARRAY_BUFFER,
                                glBindBuffer, glBufferData, glGenBuffers;
}

mixin template BufferData() {
    void[] data;
    GLenum type;
    GLint size;
    GLenum hint;

    private void set_buffer_data(void[] d, GLenum t, GLenum h) {
        data = d;
        type = t;
        hint = h;
    }
}

struct ElementBuffer {
    mixin BufferData;
    
    GLuint buffer;
    
    //@disable this();
    static ElementBuffer opCall() { return ElementBuffer(0); }
    private this(ubyte x) { glGenBuffers(1, &buffer); }
    this(void[] data, GLenum type, GLenum hint = GL_STATIC_DRAW) {
        glGenBuffers(1, &buffer);
        set_data(data, type, hint);
    }
    
    void bind() { glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer); }
    void unbind() { glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0); }
    
    void set_data(void[] data, GLenum type, GLenum hint = GL_STATIC_DRAW) {
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer); // or bind()
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, data.length, data.ptr, hint);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0); //or unbind()
        
        set_buffer_data(data, type, hint);
    }

    bool opCast(T : bool)() { return cast(bool)(data.length); }
}


struct Buffer {
    mixin BufferData;
    
    GLsizei stride;
    
    GLuint buffer;
    
    //@disable this();
    static Buffer opCall() { return Buffer(0); }
    private this(ubyte x) { glGenBuffers(1, &buffer); }
    this(void[] data, GLenum type, GLint size_=4, GLsizei stride_=0, GLenum hint = GL_STATIC_DRAW) {
        glGenBuffers(1, &buffer);
        stride = stride_;
        size = size_;
        set_data(data, type, hint);
    }
    
    void bind() { glBindBuffer(GL_ARRAY_BUFFER, buffer); }
    void bind(GLuint attrib_location, GLint size_=-1, GLsizei offset=0, GLsizei stride_=-1) {
        glBindBuffer(GL_ARRAY_BUFFER, buffer);
        int s = stride_ >= 0 ? stride_:stride;
        GLint si = size_ >= 1 ? size_:size;
        glEnableVertexAttribArray(attrib_location);
        glVertexAttribPointer(attrib_location, si, type, GL_FALSE, s, cast(void *)offset);
    }
    void unbind() { glBindBuffer(GL_ARRAY_BUFFER, 0); }
    
    void set_data(void[] data, GLenum type, GLenum hint = GL_STATIC_DRAW) {
        glBindBuffer(GL_ARRAY_BUFFER, buffer); // or bind()
        glBufferData(GL_ARRAY_BUFFER, data.length, data.ptr, hint);
        glBindBuffer(GL_ARRAY_BUFFER, 0); //or unbind()
    
        set_buffer_data(data, type, hint);
    }
    
    bool opCast(T : bool)() { return cast(bool)(data.length); }
}


GLuint gen_gl_buffer() {
    GLuint buffer;
    
    glGenBuffers(1, &buffer);
    
    return buffer;
}

GLuint[] gen_gl_buffers(int n = 1)() {
    GLuint[n] buffers;
    
    glGenBuffers(n, &buffers);
    
    return buffers;
}