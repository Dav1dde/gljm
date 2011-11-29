module gljm.parser.util;

private {
    import derelict.opengl.gl : GL_BYTE, GL_UNSIGNED_BYTE, GL_SHORT, GL_UNSIGNED_SHORT,
                                GL_INT, GL_UNSIGNED_INT, GL_FLOAT, GL_DOUBLE, GLenum;
    import std.conv : to;
}


T[][] quad2triangle(T)(T[] quad) {
    return [[quad[0], quad[1], quad[2]], [quad[0], quad[2], quad[3]]];
}

T[] flatten(T)(T[][] arr) {
    T[] res;
    
    foreach(T[] a1; arr) {
        foreach(T a2; a1) {
            res ~= a2;
        }
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

void[] convert_value(string value, GLenum type) {
    switch(type) {
        case GL_BYTE: byte b = to!(byte)(value); return ((&b)[0 .. byte.sizeof]);
        case GL_UNSIGNED_BYTE: ubyte b = to!(ubyte)(value); return (&b)[0 .. ubyte.sizeof];
        case GL_SHORT: short b = to!(short)(value); return (&b)[0 .. short.sizeof];
        case GL_UNSIGNED_SHORT: ushort b = to!(ushort)(value); return (&b)[0 .. ushort.sizeof];
        case GL_INT: int b = to!(int)(value); return (&b)[0 .. int.sizeof];
        case GL_UNSIGNED_INT: uint b = to!(uint)(value); return (&b)[0 .. uint.sizeof];
        case GL_FLOAT: float b = to!(float)(value); return (&b)[0 .. float.sizeof];
        case GL_DOUBLE: double b = to!(double)(value); return (&b)[0 .. double.sizeof];
    }
}