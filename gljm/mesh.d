module gljm.mesh;

private {
    import std.variant : Variant;
    import std.file : readText;
    import libdjson.json : JSONType, JSONObject, readJSON;
    import std.array : split;
    import std.conv : to;
    import derelict.opengl.gl : GL_ELEMENT_ARRAY_BUFFER, GL_ARRAY_BUFFER, GLsizei;
    import gljm.util : glenum2type, conv_array;
    import gljm.vbo : Buffer;
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
    Mesh m;
    
    foreach(string key, JSONType value; jobj) {
        if(key == "indices") {
            string name = key;
            
            ushort[] data;
            foreach(JSONType num; value) {
                data ~= to!(ushort)(num.toJSONNumber.getLong());
            }
            
            auto buffer = Buffer!(ushort, GL_ELEMENT_ARRAY_BUFFER)(data);
            m.set(name, buffer);
        } else {
            auto arr = split(key, "_");
            assert(arr.length == 2);
            
            string name = arr[0];
            GLsizei size = to!(GLsizei)(arr[1][0]);
            char ctype = arr[1][1];
            
            real[] data;
            foreach(JSONType num; value) {
                data ~= num.toJSONNumber.get();
            }
            
            Variant buffer; 
            switch(ctype) {
                case 'f': buffer = Buffer!(float, GL_ARRAY_BUFFER)(conv_array!(float)(data)); break;
                case 's': buffer = Buffer!(ushort, GL_ARRAY_BUFFER)(conv_array!(ushort)(data)); break;
                case 'i': buffer = Buffer!(int, GL_ARRAY_BUFFER)(conv_array!(int)(data)); break;
                default: throw new Exception("key \"" ~ key ~ "\" has unknown type \"" ~ ctype ~ "\", just f, s and i supported");  break;
            }
            
            m.set(name, buffer);
        }
    }
    
    return m;
}

Mesh load_mesh(string jstring) {
    return load_mesh(readJSON(jstring).toJSONObject);
}

Mesh load_mesh_from_file(string path) {
    return load_mesh(readText(path));
}

