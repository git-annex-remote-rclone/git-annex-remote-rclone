#!/usr/bin/env python

# Portions of this script Copyright (C) 2016 Daniel Dent

## CALL THIS SCRIPT USING generate-migration-script.sh

# based on: https://gist.github.com/giomasce/a7802bda1417521c5b30

# See docs in http://git-annex.branchable.com/internals/hashing/ and implementation in http://sources.debian.net/src/git-annex/5.20140227/Locations.hs/?hl=408#L408

# Cross-language meta-programming. This python script generates a shell migration script.

import os.path
import sys
import hashlib
import struct

def hashdirlower(key):
    hasher = hashlib.md5()
    hasher.update(key)
    digest = hasher.hexdigest()
    return "%s/%s/" % (digest[:3], digest[3:6])

def hashdirmixed(key):
    hasher = hashlib.md5()
    hasher.update(key)
    digest = hasher.digest()
    first_word = struct.unpack('<I', digest[:4])[0]
    nums = [first_word >> (6 * x) & 31 for x in xrange(4)]
    letters = ["0123456789zqjxkmvwgpfZQJXKMVWGPF"[i] for i in nums]
    return "%s%s/%s%s/" % (letters[1], letters[0], letters[3], letters[2])

count = 0
for line in sys.stdin:
    sline = line.strip()
    base = os.path.basename(sline)
    sorta_mixed = hashdirmixed(base).lower()
    lower = hashdirlower(base)
    if sline==sorta_mixed + base:
        count += 1
        print "rclone move " + sys.argv[1] + "/" + sorta_mixed + base + " " + sys.argv[1] + "/" + lower + base
    
print "echo FINISHED. MIGRATED " + str(count) + " OBJECTS."
