module gljm.parser.ply;

private {
    import derelict.opengl.gl : GL_BYTE, GL_UNSIGNED_BYTE, GL_SHORT, GL_UNSIGNED_SHORT,
                                GL_INT, GL_UNSIGNED_INT, GL_FLOAT, GL_DOUBLE, GLenum;
    import std.string : splitLines, strip, format;
    import std.algorithm : map, filter, startsWith, countUntil;
    import std.array : array, split;
    import std.conv : to;
    import std.file : readText;
    import gljm.parser.util : convert_value, flatten, quad2triangle;
    import gljm.mesh : Mesh;
    import gljm.vbo : ElementBuffer, Buffer;
    import gljm.util : glenum2size;
}

enum Format {
    ascii,
    big_endian,
    little_endian
}

enum PropertyType {
    normal,
    list
}

GLenum[string] TYPES;
static this() {
    TYPES = ["char" : GL_BYTE, "uchar" : GL_UNSIGNED_BYTE,
             "short" : GL_SHORT, "ushort" : GL_UNSIGNED_SHORT,
             "int" : GL_INT, "uint" : GL_UNSIGNED_INT,
             "float" : GL_FLOAT, "double" : GL_DOUBLE];
}


struct Property {
    string name;
    GLenum data_type;
    PropertyType type;
    GLenum lc_type;
    
    this(string name_, GLenum data_type_, PropertyType type_) {
        name = name_;
        data_type = data_type_;
        type = type_;
    }
    
    this(string name_, GLenum data_type_, PropertyType type_, GLenum lc_type_) {
        name = name_;
        data_type = data_type_;
        type = type_;
        lc_type = lc_type_;
    }
}

struct Element {
    Property[] properties;
    
    uint count;
    string name;
    void[][] data;

    
    this(string name_, uint count_) {
        name = name_;
        count = count_;
    }
}

struct Ply {
    Format format;
    Element[string] elements;
    
    this(Format f) {
        format = f;
    }
}

Ply parse_ply(string data) {
    if(!startsWith(data, "ply")) {
        throw new Exception("invalid data format");
    }
    
    string[] lines = array(filter!("a.length > 0")(map!(strip)(splitLines(data))));
    Ply ply = Ply(Format.ascii);
    Element* cur_element;
    bool got_element;
    
    string[] l1 = split(lines[1]);
    if(l1.length < 3 || l1[1] != "ascii" || l1[2] != "1.0") {
        throw new Exception("unsupported ply format");
    }
    
    uint lc = 2; // current line-number
    floop:
    foreach(string line; lines[2..$]) {
        lc++; 
        
        string[] sline = split(line);
        
        switch(sline[0]) {
            case "comment": continue;
            case "element": {
                ply.elements[sline[1]] = Element(sline[1], to!(uint)(sline[2]));
                cur_element = &(ply.elements[sline[1]]);
                got_element = true;
                break;
            }
            case "end_header": break floop;
            case "property": {
                if(!got_element) {
                    throw new Exception("no element before property declared");
                }
                
                if(sline.length == 3) {
                    if(sline[1] in TYPES) {
                        cur_element.properties ~= Property(sline[2], TYPES[sline[1]], PropertyType.normal);
                    } else {
                        throw new Exception(format("unknown type \"%s\" at line %d", sline[1], lc));
                    }
                } else if(sline.length == 5) {
                    if(sline[1] == "list") {
                        if((sline[2] in TYPES) && (sline[3] in TYPES)) {
                            cur_element.properties ~= Property(sline[4], TYPES[sline[3]], PropertyType.list, TYPES[sline[2]]);
                        } else {
                            throw new Exception(format("unknown type \"%s\" at line %d", (sline[2] in TYPES ? sline[3] : sline[2]), lc));
                        }
                    } else {
                        throw new Exception(format("unknown property type \"%s\" at line %d", sline[1], lc));
                    }
                } else {
                    throw new Exception(format("malformed property at line %d", lc));
                }
                
                break;
            }
            default: throw new Exception(format("unknown command \"%s\" at line %d (only property allowed)", sline[0], lc));
        }
    }
    
    uint cur_overall_line = lc;
    
    foreach(string s, ref Element element; ply.elements) {
        foreach(ladd; 1..element.count+1) {
            string[] sline = split(lines[(cur_overall_line+ladd)-1]); // cur_overall_line+ladd != index
            
            if(element.properties.length == 1) {
                if((element.properties[0].type != PropertyType.list) && (sline.length != 1)) {
                    throw new Exception(format("line %d doesn't match element definition", cur_overall_line+ladd));
                }
            } else if(element.properties.length != (sline.length)) {
                throw new Exception(format("line %d doesn't match element definition", cur_overall_line+ladd));
            }
            
            for(int i = 0; i < element.properties.length; i++) {
                Property prop = element.properties[i];
                if(prop.type == PropertyType.normal) {
                    element.data ~= convert_value(sline[i], prop.data_type);
                } else if(prop.type == PropertyType.list) {
                    if(element.properties.length > 1) {
                        throw new Exception("mixed list and normal properties aren't supported yet");
                    }
                    
                    uint length = to!(uint)(sline[0]);
                    if(length != (sline.length - 1)) {
                        throw new Exception(format("not enough values for list at line %d", cur_overall_line+ladd));
                    }
                    
                    void data[];
                    foreach(string s; sline[1..$]) {
                        data ~= convert_value(s, prop.data_type);
                    }
                    
                    element.data ~= data;
                }
            }
        }
        cur_overall_line += element.count;
    }
        
    return ply;
}

Ply parse_ply_from_file(string path) {
    return parse_ply(readText(path));
}

Mesh load_ply_mesh(Ply ply, string[][string][string] locs, string indices = "") {
    Mesh mesh;
    
    if(indices in ply.elements) { // is there an indices buffer defined?
        if(ply.elements[indices].properties.length) {
            void[] s;
            // all datatypes must have the same size in memory!
            uint size = glenum2size(ply.elements[indices].properties[0].data_type);
            foreach(void[] inner; ply.elements[indices].data) {
                if(inner.length == 4*size) { // quad
                    void[][][] tris = quad2triangle(inner, size);
                    s ~= flatten(tris[0]); s ~= flatten(tris[1]);
                } else if(inner.length == 3*size) { // triangle
                    s ~= inner;
                } else {
                    throw new Exception(format("unsupported number of indices in element \"%s\"", indices));
                }
            }
            mesh.indices = ElementBuffer(s, ply.elements[indices].properties[0].data_type);       
        } else {
            throw new Exception("indices element has no properties");
        }
    }
    
    foreach(string ele, string[][string] r; locs) {
        Element* cur_ele = &(ply.elements[ele]);
        foreach(string loc, string[] props; r) {            
            int[string] i;
            foreach(string prop; props) {
                i[prop] = to!(int)(countUntil!("a.name == b")(cur_ele.properties, prop));
            }
            
            void[] buf;
            for(size_t c = 0; c < cur_ele.count * cur_ele.properties.length; c += cur_ele.properties.length){
                foreach(string key; props) {
                    if(i[key] >= 0) {
                        buf ~= cur_ele.data[c+i[key]];
                    }
                }
            }

            mesh.buffer.set(loc, Buffer(buf, cur_ele.properties[0].data_type, to!(int)(props.length)));
        }
        
    }
    
    
    return mesh;
}

Mesh load_ply_mesh(Ply ply) {
    return load_ply_mesh(ply, ["vertex" : ["position" : ["x", "y", "z"],
                                           "normal" : ["nx", "ny", "nz"],
                                           "color" : ["red", "green", "blue", "alpha"]]], "face");
}

Mesh load_ply_mesh(string data) {
    return load_ply_mesh(parse_ply(data));
}

Mesh load_ply_mesh(string data, out Ply ply) {
    ply = parse_ply(data);
    return load_ply_mesh(ply);
}

Mesh load_ply_mesh_from_file(string path) {
    return load_ply_mesh(readText(path));
}

Mesh load_ply_mesh_from_file(string path, out Ply ply) {
    return load_ply_mesh(readText(path), ply);
}