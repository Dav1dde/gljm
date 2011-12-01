module gljm.parser.obj;

private {
    import gljm.mesh : Mesh;
    import gljm.vbo : ElementBuffer, Buffer;
    import gljm.util : conv_array;
    import gljm.parser.util : quad2triangle, flatten;
    import derelict.opengl.gl : GL_UNSIGNED_INT, GL_FLOAT;
    import std.file : readText;
    import std.string : splitlines, strip, format;
    import std.array : split, array;
    import std.algorithm : map;
    import std.conv : to;
    import std.range : chain;
    
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
    int v_length = 0;
    int vt_length = 0;
    int vn_length = 0;
    const int f_length = 3;
    
    float[][] v;
    float[][] vt;
    float[][] vn;
    Face[] f;
}

Obj parse_obj(string data) {
    Obj cur_obj;
    uint lc = 0;
    
    foreach(string line; splitlines(data)) {
        lc++;
        line = strip(line);
        if(!line.length) { continue; }
        string[] sline = split(line);
        
        switch(line[0]) {
            case '#': continue; break;
            case 'o': debug { writefln("obj: object-name definitions not implemented (line %d)", lc); } break;
            case 'v': {
                float[] args = conv_array!(float)(sline[1..$]);
                
                switch(line[1]) {
                    case ' ': {
                        cur_obj.v ~= args;
                        if(!cur_obj.v_length) { cur_obj.v_length = to!(int)(args.length); }
                        else { if(args.length != cur_obj.v_length) {
                            throw new Exception(format("mismatching number of vertex-coordinates at line %d", lc)); }
                        }
                        break;
                    }
                    case 't': {
                        cur_obj.v ~= args;
                        if(!cur_obj.vt_length) { cur_obj.vt_length = to!(int)(args.length); }
                        else { if(args.length != cur_obj.vt_length) {
                            throw new Exception(format("mismatching number of texture-coordinates at line %d", lc)); }
                        }
                        break;
                    }
                    case 'n': {
                        cur_obj.vn ~= args;
                        if(!cur_obj.vn_length) { cur_obj.vn_length = to!(int)(args.length); }
                        else { if(args.length != cur_obj.vn_length) {
                            throw new Exception(format("mismatching number of normal-coordinates at line %d", lc)); }
                        }
                        break;
                    }
                    default: throw new Exception(format("unknown definition \"%s\" at line %d", sline[0], lc));
                }
                break;
            }
            case 'm': {
                debug { writefln("obj: material template libraries not implemented"); }
                if(sline[0] != "mtllib") {
                    throw new Exception(format("unknown definition \"%s\" at line %d", sline[0], lc));
                }
                break;
            }
            case 'u': {
                debug { writefln("obj: material template libraries not implemented"); }
                if(sline[0] != "usemtl") {
                    throw new Exception(format("unknown definition \"%s\" at line %d", sline[0], lc));
                }
                
                break;
            }
            case 'g': debug { writefln("obj: group definitions not implemented (line %d)", lc); } break;
            case 's' : {    
                debug { writefln("obj: smooth shading not implemented"); }
                break;
            }
            case 'f': {
                string[] args = sline[1..$];
                               
                string[][] tris = [args];
                if(args.length == 4) {
                    tris = quad2triangle(args);
                } else if((args.length > 4) || (args.length < 3)) {
                    throw new Exception(format("too short or too long face definition at line %d", lc));
                }
                
                foreach(string[] tri; tris) {
                    foreach(string arg; tri) {
                        Face f;
                        string[] s = split(arg, "/");

                        switch(s.length) {
                            case 1: f.v_index = to!(uint)(s[0]); break;
                            case 2: f.v_index = to!(uint)(s[0]);
                                    f.vt_index = to!(uint)(s[1]); break;
                            case 3:
                                    f.v_index = to!(uint)(s[0]);
                                    if(s[1]) { f.vt_index = to!(uint)(s[1]); }
                                    f.vn_index = to!(uint)(s[2]);
                        default: throw new Exception(format("malformed face definition at line %d", lc));
                        }
                        --f.v_index; --f.vt_index; --f.vn_index;
                    
                        cur_obj.f ~= f;
                    }
                }
                
                break;
            }
            default: throw new Exception(format("unknown definition \"%s\" at line %d", sline[0], lc));
        }
    }
    
    return cur_obj;
}

Obj parse_obj_from_file(string path) {
    return parse_obj(readText(path));
}

Mesh load_obj_mesh(Obj obj) {
    Mesh mesh;
    
    mesh.indices = ElementBuffer(array(map!("a.v_index")(obj.f)), GL_UNSIGNED_INT);
    
    mesh.buffer.set("position", Buffer(flatten(obj.v), GL_FLOAT, obj.v_length));
    if(obj.vt) mesh.buffer.set("textcoord", Buffer(flatten(obj.vt), GL_FLOAT, obj.vt_length));
    if(obj.vn) mesh.buffer.set("normal", Buffer(flatten(obj.vn), GL_FLOAT, obj.vn_length));
    
    return mesh;
}

Mesh load_obj_mesh(string data) {
    return load_obj_mesh(parse_obj(data));
}

Mesh load_obj_mesh_from_file(string path) {
    return load_obj_mesh(readText(path));
}