module gljm.parser.obj;

private {
    import gljm.mesh : Mesh;
    import gljm.util : conv_array;
    import std.file : readText;
    import std.string : splitlines, strip;
    import std.array : split;
    import std.algorithm : map;
    import std.conv : to;
    
    debug {
        import std.stdio : writefln;
    }
}


struct Face {
    uint v_index;
    uint vt_index;
    uint vn_index;
}

struct Obj {
    string o;
    alias o name;
    string g;
    alias g group;
    
    string mtl;
        
    float[][] v;
    float[][] vt;
    float[][] vn;
    Face[] f;
}

Obj[] parse_obj(string data) {
    Obj[] obj;
    Obj cur_obj;
    
    foreach(string line; splitlines(data)) {
        line = strip(line);

        switch(line[0]) {
            case '#': continue; break;
            case 'o': {
                if(cur_obj.name) {
                    obj ~= cur_obj;
                }
                cur_obj = Obj();
                cur_obj.name = split(line)[1];
                
                break;
            }
            case 'v': {
                float[] args = conv_array!(float)(split(line)[1..$]);

                switch(line[1]) {
                    case ' ': cur_obj.v ~= args; break;
                    case 't': cur_obj.vt ~= args; break;
                    case 'n': cur_obj.vn ~= args; break;
                    default: throw new Exception("");
                }
                break;
            }
            case 'm': {
                debug { writefln("obj: material template libraries not implemented"); }
                string[] s = split(line);
                if(s[0] != "mtllib") {
                    throw new Exception("");
                }
                break;
            }
            case 'u': {
                debug { writefln("obj: material template libraries not implemented"); }
                string[] s = split(line);
                if(s[0] != "usemtl") {
                    throw new Exception("");
                }
                
                break;
            }
            case 'g': {
                cur_obj.group = split(line)[1];
                break;
            }
            case 's' : {    
                debug { writefln("obj: smooth shading not implemented"); }
                break;
            }
            case 'f': {
                Face f;
                string[] args = split(line)[1..$];
                
                foreach(string arg; args) {
                    string[] s = split(arg, "/");
                    
                    switch(s.length) {
                        case 1: f.v_index = to!(uint)(s[0]); break;
                        case 2: f.v_index = to!(uint)(s[0]);
                                f.vt_index = to!(uint)(s[1]); break;
                        case 3:
                                f.v_index = to!(uint)(s[0]);
                                if(s[1]) { f.vt_index = to!(uint)(s[1]); }
                                f.vn_index = to!(uint)(s[2]);
                    default: throw new Exception("");
                    }
                
                    cur_obj.f ~= f;
                }
                
                break;
            }
            default: throw new Exception("");
        }
    }
    
    obj ~= cur_obj;
    
    return obj;
}

Obj[] parse_obj_from_file(string path) {
    return parse_obj(readText(path));
}