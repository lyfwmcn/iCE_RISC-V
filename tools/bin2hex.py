#!/usr/bin/env python3
"""Convert bin/test to the two EBR lane hex files used by SystemBus.v.

Lane layout (must match SystemBus.v comments):
  mem0[w] = {1'b0, byte[4w+1], 1'b0, byte[4w]}  -> value = (b1 << 9) | b0
  mem1[w] = {1'b0, byte[4w+3], 1'b0, byte[4w+2]} -> value = (b3 << 9) | b2

Usage: bin2hex.py <input.bin> [mem0.hex mem1.hex]
Both hex files get exactly 1024 lines (4KB, zero-padded).
"""

import sys

def main() -> None:
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    src = sys.argv[1]
    out0 = sys.argv[2] if len(sys.argv) > 2 else "mem0.hex"
    out1 = sys.argv[3] if len(sys.argv) > 3 else "mem1.hex"

    with open(src, "rb") as f:
        data = f.read()
    data = data + bytes(4096 - len(data))  # pad to full 4KB

    with open(out0, "w") as f0, open(out1, "w") as f1:
        for w in range(1024):
            b0, b1, b2, b3 = data[4 * w:4 * w + 4]
            f0.write(f"{((b1 << 9) | b0):05x}\n")
            f1.write(f"{((b3 << 9) | b2):05x}\n")

if __name__ == "__main__":
    main()
