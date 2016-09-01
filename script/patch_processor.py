#!/usr/bin/env python

# remove comments and preprocess qiku feature
# Author: eric yan, v1.1, 160523

import os
import sys
import re
import time
import shutil
import cStringIO

DEBUG = 1
feature_table = {}

comment_pt = re.compile(r'\/\*.*?\*\/|\/\/[^\r\n]*', re.S|re.M)
feature_pt = re.compile('QikuFeatureUtils.get\w+\s*\(\s*"([^ ]+?)"\s*[^)]*?\)')

def usage(argv):
    print >>sys.stderr, "%s <x.patch> <platform-feature> [product-feature]" % (argv[0])
    sys.exit(1)

def get_file_content(filename):
    file_lines = []
    try:
        file_object = open(filename, "rb")
    except (IOError, OSError), e:
        sys.stderr.write("Error opening '%s'\n\t(%s)" % (filename, str(e)))
        sys.exit(-1)
    comments = []
    for linenum, line in enumerate(file_object):
        line = line.strip(" \t\r\n")
        if not line: continue
        if line[0] == '#':
            comments.append(line.strip("#"))
            continue
        file_lines.append((linenum+1, line, comments))
        comments = []
    return file_lines

def add_feature(fname, fvalue):
    global feature_table

    if fvalue[0] == 'r' or fvalue[0] == 'q':
        fvalue = fvalue[1:]
        fvalue = fvalue.strip(' \t')

    fname = fname.strip()
    fvalue = fvalue.strip(' \t\r\n;')
    feature_table[fname] = fvalue
    print("[FEATURE] adding: [%s]:[%s]" % (fname, fvalue))

def init_feature(plat_feature, prod_feature):
    
    product_lines = get_file_content(plat_feature)

    # Pattern for KEY = VALUE
    kvpattern = re.compile(r'\s*([^\s]+)\s*=\s*([^\s]+)')
    counter = 0

    if prod_feature != None:
        build_tag_lines = get_file_content(prod_feature)
        for bln, bline, bcomments in build_tag_lines:

            bmatch = kvpattern.match(bline)
            if not bmatch:
                if re.match(r'\s*([^\s]+)\s*=\s*', bline):
                    # No value!!
                    sys.stderr.write("Syntax error: '%s', at (%s:%s)\n" % (bline, prod_feature, bln))
                    return False
                continue
            bname, bvalue = bmatch.groups()
            for pln, pline, comments in product_lines:
                product_match_str = "%s\s*=" % bname
                if not re.match(product_match_str, pline):
                    continue
                counter += 1
                # Remove feature being added from product_features
                product_lines.remove((pln, pline, comments))

            # add key-val pairs into table
            add_feature(bname, bvalue)

    for pln, pline, comments in product_lines:
        # Match key-val pairs in product features
        match = kvpattern.match(pline)
        if not match:
            if re.match(r'\s*([^\s]+)\s*=\s*', pline):
                # No value!!
                sys.stderr.write("Syntax error: '%s', at (%s:%s)\n" % (pline, plat_feature, pln))
                return False
            continue

        counter += 1
        fname, fvalue = match.groups()

        # add key-val pairs into table
        add_feature(fname, fvalue)

    print "%d features found.\n" % counter

def get_feature_value(fname):
    fvalue = feature_table.get(fname)
    if fvalue:
        return fvalue
    return None

def feature_repl(matchobj):
    fvalue = None
    fname = matchobj.groups()[0]
    if fname:
        fvalue = get_feature_value(fname)

    if fvalue:
        return fvalue
    else:
        return matchobj.group()

def comment_repl(matchobj):
    line_buff = []
    repl_buff = matchobj.group().split('\n')
    for cl in repl_buff:
        # foo = "file:///xxx"; or foo = "http://y/*y*/y";
        if re.match(r"^//[^\"']*[\"']+\s*[,;)].*$", cl):
            line_buff.append(cl)
            continue
        if cl[0] == '+':
            line_buff.append('+')
        else:
            line_buff.append('')
    return '\n'.join(line_buff)

def process_blockbuf(block_buff, clean_buff):
    #m_buff = comment_pt.subn(comment_repl, block_buff)

    f_buff = feature_pt.subn(feature_repl, block_buff) #m_buff[0])
    if DEBUG and (f_buff[1] > 0 ): #or m_buff[1] > 0):
        print("------\n" + block_buff)
        print("******\n%s++++++\n" % f_buff[0])

    clean_buff.write(f_buff[0])

def main(argv):

    if len(argv) < 2:
        usage(argv)

    patch_file = argv[1]
    plat_feature = sys.argv[2]
    prod_feature = None

    if len(sys.argv) > 3:
        prod_feature = sys.argv[3]

    if not os.path.isfile(patch_file):
        usage(argv)

    init_feature(plat_feature, prod_feature)

    clean_buff = cStringIO.StringIO()
    ptf = open(patch_file, "r")

    process_enable = True
    block_buff = ''
    for line in ptf.readlines():
        df = line.startswith('+++')
        if df or line.startswith('---') or line.startswith('@@'):
            clean_buff.write(line)
            if df:
                if re.match(r'^.+\.(java|c|cpp|cxx|cc|h|hpp|bk)$', line):
                    process_enable = True
                    if DEBUG:
                        print ">>> (ENABLE) %s\n" % (line)
                else:
                    process_enable = False
                    if DEBUG:
                        print ">>> (DISABLE) %s\n" % (line)
            continue

        if not process_enable:
            clean_buff.write(line)
            block_buff = ''
            continue

        if line.startswith('+'):
            block_buff += line
        else:
            if block_buff != '':
                process_blockbuf(block_buff, clean_buff)
                block_buff = ''

            clean_buff.write(line)

    if process_enable and block_buff != '':
        process_blockbuf(block_buff, clean_buff)
        block_buff = None

    ptf.close()

    ptf_new = open(patch_file+".new", "w")
    ptf_new.write(clean_buff.getvalue())
    ptf_new.close()

if __name__ == "__main__":
    main(sys.argv)