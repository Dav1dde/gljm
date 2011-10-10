module gljm.vbo;

private {
    import derelict.opengl.gl;
}

struct BufferData {
    void[] data;
    GLenum type;
    GLint size;
    GLenum hint;
    
    this(void[] data_, GLenum type_, GLint size_, GLenum hint_ = GL_STATIC_DRAW) {
        data = data_;
        type = type_;
        size = size_;
        hint = hint_;
    }
}

struct ElementBuffer {
    private BufferData _buffer_data;
    GLuint buffer;
    
    @disable this();
    static ElementBuffer opCall() { return ElementBuffer(0); }
    private this(ubyte x) { glGenBuffers(1, &buffer); }

    void bind() { glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer); }
    void unbind() { glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0); }
    
    void set_data(void[] data, GLenum hint = GL_STATIC_DRAW) {
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer); // or bind()
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, data.length, data.ptr, hint);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0); //or unbind()
        
        _buffer_data.data = data;
        _buffer_data.hint = hint;
    }

    @property void buffer_data(BufferData bd) { set_data(bd.data, bd.hint); }
    @property BufferData buffer_data() { return _buffer_data; };
}


struct Buffer {
    private BufferData _buffer_data;
    GLuint buffer;
    
    @disable this();
    static Buffer opCall() { return Buffer(0); }
    private this(ubyte x) { glGenBuffers(1, &buffer); }
    
    void bind() { glBindBuffer(GL_ARRAY_BUFFER, buffer); }
    void bind(GLuint attrib_location) {
        glBindBuffer(GL_ARRAY_BUFFER, buffer);
        glEnableVertexAttribArray(attrib_location);
        glVertexAttribPointer(attrib_location, _buffer_data.size, _buffer_data.type, false, 0, null);
    }
    void unbind() { glBindBuffer(GL_ARRAY_BUFFER, 0); }
    
    void set_data(void[] data, GLenum type, GLint size, GLenum hint = GL_STATIC_DRAW) {
        glBindBuffer(GL_ARRAY_BUFFER, buffer); // or bind()
        glBufferData(GL_ARRAY_BUFFER, data.length, data.ptr, hint);
        glBindBuffer(GL_ARRAY_BUFFER, 0); //or unbind()
    
        _buffer_data.data = data;
        _buffer_data.type = type;
        _buffer_data.size = size;
        _buffer_data.hint = hint;
    }
    
    @property void buffer_data(BufferData bd) {
        set_data(bd.data, bd.type, bd.size, bd.hint);
    }
    @property BufferData buffer_data() {
        return _buffer_data;
    };
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