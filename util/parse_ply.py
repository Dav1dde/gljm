#/usr/bin/env python
# -*- coding: utf-8 -*-

from collections import defaultdict

TYPES = ('char', 'uchar', 'short', 'ushort', 'int', 'uint', 'float', 'double')

def parse(data):
    elements = list()
    cur_element = None
    
    lines = [line.strip() for line in data.splitlines()]
    
    if not 'ply' in data[:4] or not lines[1].startswith('format'):
        raise ValueError('invalid data format.')
    
    _, type_, version = lines[1].split()
    if not type_ == 'ascii' or not version == '1.0':
        raise ValueError('unsupported ply format.')
    
    # parse the header
    for i, line in enumerate(lines[2:], 3):
        line = line.strip()
        
        if line.startswith('comment'):
            continue
        elif line.startswith('element'):
            _, name, length = line.split()
            
            elements.append({'name' : name, 'length' : int(length)})
            cur_element = elements[-1]
        elif line.startswith('end_header'):
            break # we've reached the end
        elif cur_element is None:
            raise ValueError('no element declared, line: %d.' % i)
        elif line.startswith('property'):
            parts = line.split()
            
            if len(parts) == 3:
                if parts[1] in TYPES:
                    if not 'property' in cur_element:
                        cur_element['property'] = list()
                    
                    cur_element['property'].append({'type' : parts[1],
                                                    'name' : parts[2]})
                else:
                    raise ValueError('unknown type "%s" at line %d.'
                                      % (parts[1], i))
            elif len(parts) == 5:
                if parts[1] == 'list':
                    if parts[2] in TYPES:
                        if parts[3] in TYPES:
                            cur_element['property'] = {'count' : parts[2],
                                                       'type' : parts[3],
                                                       'name' : parts[4]}
                        else:
                            raise ValueError('unknown type "%s" at line %d.'
                                              % (parts[3], i))
                    else:
                        raise ValueError('unknown type "%s" at line %d.'
                                          % (parts[2], i))
            else:
                raise ValueError('malformed property at line %d.' % i)
        else:
            raise ValueError('unknown command "%s" at line %d, only'
                             '"property" allowed.' % (line.split(None, 1)[0], i))
    
    # lines[i] = first line after end_header
    cur_element = None
    
    print elements
    
    
if __name__ == '__main__':
    parse(open('/home/dav1d/workspaces/d/gljm/zylinder.ply').read())