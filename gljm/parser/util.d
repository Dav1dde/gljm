module gljm.parser.util;


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