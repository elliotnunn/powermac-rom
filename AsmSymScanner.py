#!/usr/bin/env python3

import sys
import re
import os.path

HEADER = 'AUTO-GENERATED SYMBOL LIST'
ENC = 'macroman'
RECORD = re.compile(r'^[^;\s]*\s+record', re.I)
ENDR = re.compile(r'^\s+endr', re.I)

SETEQU = re.compile(r'^\S+\s+(dc\.|ds\.|set|equ|record)', flags=re.I)

def neaten_name(x):
    bn = os.path.basename(x)
    bn = os.path.splitext(bn)[0]
    return bn

all_args = list(sys.argv[1:])
opts = []

while all_args and all_args[0].startswith('-'):
    opts.append(all_args.pop(0))

fnames = all_args

fnames = [fn for fn in fnames if HEADER in open(fn, encoding=ENC).read(2048)]

fexports = []
for name in fnames:
    exports = set()
    can_keep = False

    with open(name, encoding=ENC) as f:
        forbid = False
        for l in f:
            if not forbid and RECORD.match(l):
                forbid=True
            elif forbid and ENDR.match(l):
                forbid=False

            if not forbid:
                m = re.match(r'^(\w+)', l)
                if m and not SETEQU.match(l):
                    exports.add(m.group(1))

    fexports.append(exports)

regex_cache = {}
for export_set in fexports:
    for export in export_set:
        if export not in regex_cache:
            regex_cache[export] = re.compile(r'^[^;]+\b' + re.escape(export) + r'\b', flags=re.I)

export_matrix = set()
for expname, exports in zip(fnames, fexports):
    for impname in fnames:
        if impname == expname: continue

        with open(impname, encoding=ENC) as f:
            for l in f:
                for e in exports:
                    er = regex_cache[e]
                    if er.match(l):
                        export_matrix.add((expname, impname, e))

for exp, imp, sym in sorted(export_matrix):
    print(exp.rpartition('/')[2], imp.rpartition('/')[2], sym)

dict_exporter = {}
for exp, imp, sym in export_matrix:
    dict_exporter[sym] = exp

dict_importers = {}
for exp, imp, sym in export_matrix:
    if sym not in dict_importers:
        dict_importers[sym] = set()
    dict_importers[sym].add(imp)

dict_fileimports = {}
for exp, imp, sym in export_matrix:
    if imp not in dict_fileimports:
        dict_fileimports[imp] = set()
    dict_fileimports[imp].add(sym)

dict_fileexports = {}
for exp, imp, sym in export_matrix:
    if exp not in dict_fileexports:
        dict_fileexports[exp] = set()
    dict_fileexports[exp].add(sym)

for f in fnames:
    if f not in dict_fileimports:
        dict_fileimports[f] = set()
    if f not in dict_fileexports:
        dict_fileexports[f] = set()

for path in fnames:
    with open(path, encoding=ENC) as i:
        with open(path + '~', 'w', encoding=ENC) as o:
            for l in i:
                o.write(l)
                if HEADER in l:
                    prefix, _, suffix = l.partition(HEADER)
                    imports = sorted(dict_fileimports[path])
                    exports = sorted(dict_fileexports[path])

                    if imports:
                        dict_exp_to_imp = {}
                        for imp in imports:
                            exporter = dict_exporter[imp]
                            if exporter not in dict_exp_to_imp:
                                dict_exp_to_imp[exporter] = set()
                            dict_exp_to_imp[exporter].add(imp)

                        o.write(prefix + 'IMPORTS:' + suffix)

                        for exp, imps in sorted(dict_exp_to_imp.items()):
                            o.write(prefix + '  ' + neaten_name(exp) + suffix)
                            for imp in sorted(imps):
                                o.write(prefix + '    ' + imp + suffix)

                    if exports:
                        o.write(prefix + 'EXPORTS:' + suffix)
                        for exp in exports:
                            importers = sorted(dict_importers[exp])
                            importers = [neaten_name(x) for x in importers]
                            impstring = ' (=> %s)' % (', '.join(importers))
                            o.write(prefix + '  ' + exp + impstring + suffix)

                    for l in i:
                        if not l.startswith(prefix):
                            o.write(l)
                            break

    open(path, 'wb').write(open(path + '~', 'rb').read().replace(b'\n', b'\r'))
    os.unlink(path + '~')
