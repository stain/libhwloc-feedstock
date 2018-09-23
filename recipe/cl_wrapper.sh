#!/usr/bin/env python
import sys
import subprocess

link_args = []
args = []
print(sys.argv)
for i, arg in enumerate(sys.argv):
    if i == 0:
        continue
    if arg.startswith("-L"):
        if arg == "-L":
            i=i+1
            arg = sys.argv[i]
        else:
            arg = arg[2:]
        link_args.append("-libpath:"+arg)
    elif arg == "-link":
        link_args.extend(sys.argv[i+1:])
        break
    elif arg == "-LD" or arg == "-LDd":
        args.append(arg)
    elif arg.startswith("-l"):
        if arg == "-lpthread":
            link_args.append("pthreads.lib")
            continue
        link_args.append(arg[2:]+".lib")
    elif arg.startswith("-Wl,"):
        link_args.extend(arg[4:].split(","))
    elif arg == "-no-undefined":
        continue
    elif arg.endswith(".lib"):
        link_args.append(arg)
    else:
        args.append(arg)

if len(link_args) > 0:
    args.append("-link")
    args.extend(link_args)

args = ["clang-cl"] + args
print(args)
try:
    subprocess.check_call(args)
except subprocess.CalledProcessError as e:
    sys.exit(e.returncode)
