module gljm.parser.obj;

private {
    import gljm.mesh : Mesh, BufInfo;
    import gljm.vbo : ElementBuffer, Buffer;
    import gljm.util : conv_array;
    import gljm.parser.util : quad2triangle, flatten, updateAA, zip;
    import derelict.opengl.gl : GL_UNSIGNED_INT, GL_FLOAT;
    import std.file : readText;
    import std.string : splitlines, strip, format;
    import std.array : split, array, join;
    import std.algorithm : map, filter;
    import std.conv : to;
    import std.range : chain;
    import std.path : buildPath;
    
    debug {
        import std.stdio : writefln;
    }
}

struct Color(type, int size) if((size == 3) || (size == 4)) {
    type[size] color;
    alias color this;
    
    private @property type get(size_t i)() { return color[i]; }
    private @property void set(size_t i)(type value) { color[i] = value; }
    
    alias get!0 r;
    alias set!0 r;
    alias get!1 g;
    alias set!1 g;
    alias get!2 b;
    alias set!2 b;
    static if(size == 4) {
        alias get!3 a;
        alias set!3 a;
    }
    
    static if(size == 3) {
        this(type r_, type g_, type b_) { r = r_; g = g_; b = b_; }
    } else {
        this(type r_, type g_, type b_, type a_) { r = r_; g = g_; b = b_; a = a_; }
    }
}

alias Color!(float, 3) color3;

struct Material {
    color3 ambient = color3(0.2f, 0.2f, 0.2f);
    color3 diffuse = color3(0.8f, 0.8f, 0.8f);
    color3 specular = color3(1.0f, 1.0f, 1.0f);
    float transparency = 1.0f;
    float shininess = 0.0f;
    ushort illum = 0;
    float optical_density = 1.0f;
}

struct Face {
    uint[] v_index;
    uint[] vt_index;
    uint[] vn_index;
    Material material;
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
    
    Material[string] materials;
}


Material[string] parse_mtl(string data) {
    Material[string] mtls;
    Material *cur_mtl;
    bool got_mtl = false;
    uint lc = 0;
    
    foreach(string line; splitlines(data)) {
        lc++;
        line = strip(line);
        if(!line.length || line[0] == '#') { continue; }
        string[] sline = split(line);
        
        if(!got_mtl && sline[0] != "newmtl") {
            throw new Exception("material must be defined before anything else.");
        }
        
        switch(sline[0]) {
            case "newmtl": 
                Material m;
                string k = sline.length == 2 ? sline[1]:"";
                mtls[k] = m;
                cur_mtl = &mtls[k];
                got_mtl = true;
                break;
            case "Ka": {
                if(sline.length != 4) {
                    throw new Exception(format("malformed ambient color at line: %d.", lc));
                }
                
                cur_mtl.ambient = color3(to!(float)(sline[1]), to!(float)(sline[2]), to!(float)(sline[3]));
                break;
            }
            case "Kd": {
                if(sline.length != 4) {
                    throw new Exception(format("malformed ambient color at line: %d.", lc));
                }
                
                cur_mtl.diffuse = color3(to!(float)(sline[1]), to!(float)(sline[2]), to!(float)(sline[3]));
                break;
            }
            case "Ks": {
                if(sline.length != 4) {
                    throw new Exception(format("malformed ambient color at line: %d.", lc));
                }
                
                cur_mtl.specular = color3(to!(float)(sline[1]), to!(float)(sline[2]), to!(float)(sline[3]));
                break;
            }
            case "d":
            case "Tr":
                if(sline.length != 2) {
                    throw new Exception(format("malformed transparency at line: %d.", lc));
                }
                
                cur_mtl.transparency = to!(float)(sline[1]);
                break;
            case "Ns":
                if(sline.length != 2) {
                    throw new Exception(format("malformed shininess at line: %d.", lc));
                }
                
                cur_mtl.shininess = to!(float)(sline[1]);
                break;
            case "Ni":
                if(sline.length != 2) {
                    throw new Exception(format("malformed optical density at line: %d.", lc));
                }
                
                cur_mtl.optical_density = to!(float)(sline[1]);
                break;
            case "illum": 
                if(sline.length != 2) {
                    throw new Exception(format("malformed illumination model at line: %d.", lc));
                }
                
                ushort illum = to!(ushort)(sline[1]);
                if(illum > 10) {
                    throw new Exception(format("illumination model exceeds \"10\" at line: %d.", lc));
                }
                cur_mtl.illum = illum;
                break;
            default:
                //throw new Exception(format("unknown mtl-definition \"%s\" at line %d.", sline[0], lc));
                debug { writefln("unknown mtl-definition \"%s\" at line %d.", sline[0], lc); }
        }
    }
    
    return mtls;
}

Obj parse_obj(string data, string mtl_path = "") {
    Obj cur_obj;
    Material cur_mtl;
    uint lc = 0;
    
    foreach(string line; splitlines(data)) {
        lc++;
        line = strip(line);
        if(!line.length) { continue; }
        string[] sline = split(line);
        
        switch(line[0]) {
            case '#': continue;
            case 'o': debug { writefln("obj: object-name definitions not implemented (line %d).", lc); } break;
            case 'v': {
                float[] args = conv_array!(float)(sline[1..$]);
                
                switch(line[1]) {
                    case ' ': {
                        cur_obj.v ~= args;
                        if(!cur_obj.v_length) { cur_obj.v_length = to!(int)(args.length); }
                        else { if(args.length != cur_obj.v_length) {
                            throw new Exception(format("mismatching number of vertex-coordinates at line %d.", lc)); }
                        }
                        break;
                    }
                    case 't': {
                        cur_obj.vt ~= args;
                        if(!cur_obj.vt_length) { cur_obj.vt_length = to!(int)(args.length); }
                        else { if(args.length != cur_obj.vt_length) {
                            throw new Exception(format("mismatching number of texture-coordinates at line %d.", lc)); }
                        }
                        break;
                    }
                    case 'n': {
                        cur_obj.vn ~= args;
                        if(!cur_obj.vn_length) { cur_obj.vn_length = to!(int)(args.length); }
                        else { if(args.length != cur_obj.vn_length) {
                            throw new Exception(format("mismatching number of normal-coordinates at line %d.", lc)); }
                        }
                        break;
                    }
                    default: throw new Exception(format("unknown definition \"%s\" at line %d.", sline[0], lc));
                }
                break;
            }
            case 'm': {
                if(sline[0] != "mtllib") {
                    throw new Exception(format("unknown definition \"%s\" at line %d.", sline[0], lc));
                } else if(sline.length != 2) {
                    throw new Exception(format("malformed mtllib declaration at line %d.", lc));
                }
                if(mtl_path.length) {
                    updateAA(cur_obj.materials, parse_mtl(readText(buildPath(mtl_path, sline[1]))));
                } else {
                    debug { writefln("obj: no path to material template libraries passed."); }
                }
                break;
            }
            case 'u': {
                if(sline[0] != "usemtl") {
                    throw new Exception(format("unknown definition \"%s\" at line %d.", sline[0], lc));
                }
                string k = sline.length == 2 ? sline[1]:"";
                if(k in cur_obj.materials) {
                    cur_mtl = cur_obj.materials[k];
                } else {
                    debug { writefln("obj: no matching material for \"%s\" found (line %d).", k, lc); }
                    cur_mtl = Material();
                }
                break;
            }
            case 'g': debug { writefln("obj: group definitions not implemented (line %d).", lc); } break;
            case 's' : debug { writefln("obj: smooth shading not implemented"); } break;
            case 'f': {
                string[] args = sline[1..$];
                               
                string[][] tris = [args];
                if(args.length == 4) {
                    tris = quad2triangle(args);
                } else if((args.length > 4) || (args.length < 3)) {
                    throw new Exception(format("too short or too long face definition at line %d.", lc));
                }
                
                foreach(string[] tri; tris) {
                    Face f;
                    foreach(string arg; tri) {
                        string[] s = split(arg, "/");

                        switch(s.length) {
                            case 1: f.v_index ~= to!(uint)(s[0])-1; break;
                            case 2: f.v_index ~= to!(uint)(s[0])-1;
                                    f.vt_index ~= to!(uint)(s[1])-1; break;
                            case 3:
                                    f.v_index ~= to!(uint)(s[0])-1;
                                    if(s[1]) { f.vt_index ~= to!(uint)(s[1])-1; }
                                    f.vn_index ~= to!(uint)(s[2])-1; break;
                            default: throw new Exception(format("malformed face definition at line %d.", lc));
                        }
                    }
                    f.material = cur_mtl;
                    cur_obj.f ~= f;
                }
                
                break;
            }
            default: throw new Exception(format("unknown definition \"%s\" at line %d.", sline[0], lc));
        }
    }
    
    return cur_obj;
}

Obj parse_obj_from_file(string path) {
    return parse_obj(readText(path));
}

Mesh load_obj_mesh(Obj obj) {
    Mesh mesh;
    
    mesh.indices = ElementBuffer(join(map!("chain(a.v_index, a.vt_index, a.vn_index)")(obj.f)), GL_UNSIGNED_INT);
    
    int cur_off = 0;
    BufInfo[string] s = ["position" : BufInfo(obj.v_length, cur_off)];
    cur_off += obj.v_length*float.sizeof;
    
    int stride = (obj.v_length+obj.vt_length+obj.vn_length)*float.sizeof;
        
    float[][][] d = [obj.v];
    
    if(obj.vt) {
        s["texcoord"] = BufInfo(obj.vt_length, cur_off);
        cur_off += obj.vt_length*float.sizeof;
        d ~= obj.vt;
    } if(obj.vn) {
        s["normal"] = BufInfo(obj.vn_length, cur_off);
        cur_off += obj.vn_length*float.sizeof;
        d ~= obj.vn;
    }
    
    mesh.buffer.set(s, Buffer(flatten(zip(d)), GL_FLOAT, 3, stride));
    
    return mesh;
}

Mesh load_obj_mesh(string data, string mtl_path = "") {
    Obj obj;
    return load_obj_mesh(data, obj);
}

Mesh load_obj_mesh(string data, out Obj obj, string mtl_path = "") {
    obj = parse_obj(data, mtl_path);
    return load_obj_mesh(obj);
}

Mesh load_obj_mesh_from_file(string path, string mtl_path = "") {
    return load_obj_mesh(readText(path), mtl_path);
}

Mesh load_obj_mesh_from_file(string path, out Obj obj, string mtl_path = "") {
    return load_obj_mesh(readText(path), obj, mtl_path);
}