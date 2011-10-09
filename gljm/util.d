module gljm.util;

private {
    import derelict.opengl.gl;
}

template type2glenum(T) {
    static if(is(T == byte)) {
        GLenum type2glenum = GL_BYTE;
    } else static if(is(T == ubyte)) {
        GLenum type2glenum = GL_UNSIGNED_BYTE;
    } else static if(is(T == short)) {
        GLenum type2glenum = GL_SHORT;
    } else static if(is(T == ushort)) {
        GLenum type2glenum = GL_UNSIGNED_SHORT;
    } else static if(is(T == int)) {
        GLenum type2glenum = GL_INT;
    } else static if(is(T == uint)) {
        GLenum type2glenum = GL_UNSIGNED_INT;
    } else static if(is(T == float)) {
        GLenum type2glenum = GL_FLOAT;
    } else static if(is(T == double)) {
        GLenum type2glenum = GL_DOUBLE;
    } else {
        static assert(false, T.stringof ~ " cannot be represented as GLenum");
    }
}

template glenum2type(GLenum t) {
    static if(t == GL_BYTE) {
        alias byte glenum2type;
    } else static if(t == GL_UNSIGNED_BYTE) {
        alias ubyte glenum2type;
    } else static if(t == GL_SHORT) {
        alias short glenum2type;
    } else static if(t == GL_UNSIGNED_SHORT) {
        alias ushort glenum2type;
    } else static if(t == GL_INT) {
        alias int glenum2type;
    } else static if(t == GL_UNSIGNED_INT) {
        alias uint glenum2type;
    } else static if(t == GL_FLOAT) {
        alias float glenum2type;
    } else static if(t == GL_DOUBLE) {
        alias double glenum2type;
    } else {
        static assert(false, T.stringof ~ " cannot be represented as D-Type");
    }
}

unittest {
    assert(GL_BYTE == type2glenum!byte);
    assert(GL_UNSIGNED_BYTE == type2glenum!ubyte);
    assert(GL_SHORT == type2glenum!short);
    assert(GL_UNSIGNED_SHORT == type2glenum!ushort);
    assert(GL_INT == type2glenum!int);
    assert(GL_UNSIGNED_INT == type2glenum!uint);
    assert(GL_FLOAT == type2glenum!float);
    assert(GL_DOUBLE == type2glenum!double);
    
    assert(is(byte : glenum2type!GL_BYTE));
    assert(is(ubyte : glenum2type!GL_UNSIGNED_BYTE));
    assert(is(short : glenum2type!GL_SHORT));
    assert(is(ushort : glenum2type!GL_UNSIGNED_SHORT));
    assert(is(int : glenum2type!GL_INT));
    assert(is(uint : glenum2type!GL_UNSIGNED_INT));
    assert(is(float : glenum2type!GL_FLOAT));
    assert(is(double : glenum2type!GL_DOUBLE));
}