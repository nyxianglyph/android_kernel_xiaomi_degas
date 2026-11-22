#!/usr/bin/env python3
"""Compare the symbol CRCs stock vendor modules expect with a kernel build.

usage: crc_check.py <all_versions.txt> <Module.symvers> [<Module.symvers> ...]
all_versions.txt lines: "<module.ko> <symbol> <0xcrc>" (from modprobe --dump-modversions)
Module.symvers lines:   "<0xcrc>\t<symbol>\t<provider>\t<export type>[\t<ns>]"
"""
import collections
import sys

expected = collections.defaultdict(dict)      # symbol -> {crc: [modules]}
for line in open(sys.argv[1]):
    mod, sym, crc = line.split()
    expected[sym].setdefault(int(crc, 16), []).append(mod)

provided = {}                                  # symbol -> (crc, provider)
for path in sys.argv[2:]:
    for line in open(path):
        f = line.rstrip("\n").split("\t")
        if len(f) >= 3:
            provided[f[1]] = (int(f[0], 16), f[2])

match, mismatch, vendor_only = [], [], []
for sym, crcs in sorted(expected.items()):
    if sym not in provided:
        vendor_only.append(sym)
        continue
    crc, prov = provided[sym]
    for want, mods in crcs.items():
        (match if want == crc else mismatch).append((sym, prov, want, crc, mods))

broken = sorted({m for *_, mods in mismatch for m in mods})
print(f"symbols expected: {len(expected)}")
print(f"  provided by this build: {len(expected) - len(vendor_only)}")
print(f"    CRC match:    {len(match)}")
print(f"    CRC MISMATCH: {len(mismatch)}")
print(f"  not in this build (vendor-module exports): {len(vendor_only)}")
print(f"modules with a mismatching symbol: {len(broken)}")
for sym, prov, want, crc, mods in mismatch[:40]:
    print(f"  {sym} ({prov}) want {want:#010x} got {crc:#010x} <- {', '.join(sorted(mods)[:4])}"
          + (" ..." if len(mods) > 4 else ""))
if broken:
    print("broken modules:", " ".join(broken))
