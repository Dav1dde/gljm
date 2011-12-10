module gljm.parser.util;

private {
    import derelict.opengl.gl : GL_BYTE, GL_UNSIGNED_BYTE, GL_SHORT, GL_UNSIGNED_SHORT,
                                GL_INT, GL_UNSIGNED_INT, GL_FLOAT, GL_DOUBLE, GLenum;
    import std.conv : to;
}


T[][] quad2triangle(T)(T[] quad) if(!is(T : void)) {
    return [[quad[0], quad[1], quad[2]], [quad[0], quad[2], quad[3]]];
}

T[][][] quad2triangle(T : void)(T[] quad, uint size = 4) {
    return [[quad[0..size], quad[1*size..2*size], quad[2*size..3*size]],
            [quad[0..size], quad[2*size..3*size], quad[3*size..4*size]]];
}

T[] flatten(T)(T[][] arr) {
    T[] res;
    
    foreach(T[] a; arr) {
        res ~= a;
    }
    
    return res;
}

struct DefaultAA(type1, type2, type1 default_) {
    private type1[type2] _store;
    alias _store this;
    
    type1 opIndex(type2 index) {
        if(index in _store) {
            return _store[index];
        } else {
            return default_;
        }
    }
    
    void opIndexAssign(type1 value, type2 index) {
        _store[index] = value;
    }
    
    void opIndexOpAssign(string op)(type1 r, type2 index) {
        if(index !in _store) {
            _store[index] = default_;
        }
        mixin("_store[index]" ~ op ~"= r;");
    }
}

unittest {
    DefaultAA!(int, string, 12) myaa;
    assert(myaa["baz"] == 12);
    assert(myaa["foo"] == 12);
    myaa["baz"] = -12;
    assert(myaa["baz"] == -12);
    assert(myaa["foo"] == 12);
    myaa["baz"] += 12;
    assert(myaa["baz"] == 0);
    myaa["foo"] -= 12;
    assert(myaa["foo"] == 0);
}

void updateAA(T1, T2)(ref T1 aa1, T2 aa2) {
    foreach(key, value; aa2) {
        aa1[key] = value;
    }
}

void[] convert_value_impl(T)(string value) {
    void[] store = new ubyte[8];
    
    T b = to!(T)(value);
    *cast(T*)(store.ptr) = b;
    return store[0 .. T.sizeof];
}
void[] convert_value(string value, GLenum type) {
    switch(type) {
        case GL_BYTE: return convert_value_impl!(byte)(value);
        case GL_UNSIGNED_BYTE: return convert_value_impl!(ubyte)(value);
        case GL_SHORT: return convert_value_impl!(short)(value);
        case GL_UNSIGNED_SHORT: return convert_value_impl!(ushort)(value);
        case GL_INT: return convert_value_impl!(int)(value);
        case GL_UNSIGNED_INT: return convert_value_impl!(uint)(value);
        case GL_FLOAT: return convert_value_impl!(float)(value);
        case GL_DOUBLE: return convert_value_impl!(double)(value);
    }
}