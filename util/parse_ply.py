#/usr/bin/env python
# -*- coding: utf-8 -*-

from collections import defaultdict
from itertools import izip

TYPES = {'char' : int, 'uchar' : int, 'short' : int, 'ushort' : int,
         'int' : int, 'uint' : int, 'float' : float, 'double' : float}

def parse(data):
    elements = list()
    cur_element = None
    
    lines = [line.strip() for line in data.strip().splitlines() if line]
    
    if not 'ply' in data[:4] or not lines[1].startswith('format'):
        raise ValueError('invalid data format.')
    
    _, type_, version = lines[1].split()
    if not type_ == 'ascii' or not version == '1.0':
        raise ValueError('unsupported ply format.')
    
    # parse the header
    for i, line in enumerate(lines[2:], 3):       
        if line.startswith('comment'):
            continue
        elif line.startswith('element'):
            _, name, length = line.split()
            
            elements.append({'name' : name, 'length' : int(length), 'data' : list()})
            cur_element = elements[-1]
        elif line.startswith('end_header'):
            break # we've reached the end
        elif cur_element is None:
            raise ValueError('no element declared at line: %d.' % i)
        elif line.startswith('property'):
            parts = line.split()
            
            if len(parts) == 3:
                if parts[1] in TYPES:
                    if not 'property' in cur_element:
                        cur_element['property'] = list()
                    
                    cur_element['type'] = 'normal'
                    
                    cur_element['property'].append({'type' : parts[1],
                                                    'name' : parts[2]})
                else:
                    raise ValueError('unknown type "%s" at line %d.'
                                      % (parts[1], i))
            elif len(parts) == 5:
                if parts[1] == 'list':
                    if parts[2] in TYPES:
                        if parts[3] in TYPES:
                            cur_element['type'] = 'list'
                            
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
    cur_overall_line = i
    
    data_iter = iter(lines[cur_overall_line:])
    for element in elements:
        for i, line in izip(xrange(1, element['length']+1), data_iter):
            parts = line.split()
            
            if element['type'] == 'list':
                if len(parts[1:]) == int(parts[0]):
                    element['data'].append(map(TYPES[element['property']
                                                            ['type']],
                                               parts[1:]))
                else:
                    raise ValueError('not enough values for list at line %d.'
                                     % (cur_overall_line+i))
            else:
                if len(parts) == len(element['property']):
                    d = [TYPES[type_](value) for type_, value in
                         zip([t['type'] for t in element['property']], parts)]
                    element['data'].append(d)
                else:
                    raise ValueError('number of defined properties mismatch '
                                     'at line %d.' % (cur_overall_line+i))
        
        cur_overall_line += i
        
        # validate
        if not element['length'] == len(element['data']):
            raise ValueError('number of items doesn\'t match element '
                             'definition. Element: "%s", expected length: %d,'
                             ' length: %d.' % (element['name'],
                                               element['length'],
                                               len(element['data'])))
    
    return elements
    

def quad2triangle(tri):
    return ([tri[0], tri[1], tri[2]], [tri[0], tri[2], tri[3]])

def mq2t(l):
    out = list()
    for data in l:
        if len(data) == 4:
            out.extend(quad2triangle(data))
        else:
            out.append(data)
    return out

def main():
    import sys, os.path, json, itertools
    
    if len(sys.argv) >= 2:
        path = sys.argv[1]
        
        if os.path.isfile(path):
            with open(path) as f:
                parsed = parse(f.read())
            
            j = dict()
            
            for l in parsed:
                if l['name'] == 'face':
                    l['data'] = mq2t(l['data'])
                else:
                    l['data'] = [d[:3] for d in l['data']]
                data = list(itertools.chain.from_iterable(l['data']))
                
                if l['type'] == 'list':
                    j[l['name']] = data
                else:
                    j[l['name'] + '_3' + l['property'][0]['type'][0]] = data
            
            print json.dumps(j)
    
    
if __name__ == '__main__':
    main()