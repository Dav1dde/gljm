module gljm.mesh;

private {
    import std.variant : Variant;
    import gljm.vbo;
}


struct Mesh { // well it's just a container
    private Variant[string] _members;
    
    Variant opDispatch(string s)() {
        return get(s);
    }
    
    void set(T)(string s, T v) {
        if(Variant.allowed!T) {
            _members[s] = v;
        } else {
            throw new Exception(T.stringof ~ " not allowed as Variant");
        }
    }
    
    Variant get(string s) {
        return _members[s];
    }
    
}

Mesh load_mesh(JSONObject jobj) {
}

Mesh load_mesh(string jstring) {
}

Mesh load_mesh_from_file(string path) {
}