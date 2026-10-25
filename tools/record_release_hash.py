#!/usr/bin/env python3
"""record_release_hash.py -- record the sha256 of lib/lnwcommands.mlib in lib/lnwcommands.mlib.release.sha256.

Run it at release time, AFTER the final rebuild of the core Mata library (set_version.py calls it too when given a version).
tools/check_version.py compares the library with this hash and warns when it changed since the last release: the Mata
libraries of nwsaom, nwergm, nwdynam and nwrem are compiled against the core library and must then be rebuilt and released in step.
"""
import hashlib, os, sys
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
lib = os.path.join(root, "lib", "lnwcommands.mlib")
if not os.path.exists(lib):
    print("record_release_hash: lib/lnwcommands.mlib not found"); sys.exit(1)
h = hashlib.sha256(open(lib, "rb").read()).hexdigest()
open(os.path.join(root, "lib", "lnwcommands.mlib.release.sha256"), "w").write(h + "  lnwcommands.mlib\n")
print("recorded lib/lnwcommands.mlib.release.sha256:", h)
