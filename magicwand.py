#!/usr/bin/python

import sys
if len(sys.argv) == 2:
    if sys.argv[1] == '-e':
        while True:
            line = sys.stdin.readline()
            if line == '':
                break
            print " ",
            for c in line:
                print "%d,  " % (ord(c)),
            print " "
    if sys.argv[1] == '-d':
        while True:
            line = sys.stdin.readline()
            if line == '':
                break
            for c in map(lambda x: x.strip(), line.split(',')):
                if c.strip() == '':
                    continue
                sys.stdout.write(str(chr(int(c))))

