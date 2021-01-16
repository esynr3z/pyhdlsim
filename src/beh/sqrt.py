#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from pathlib import Path
from math import sqrt, floor
import random


def nrsqrt(d, width=32):
    """Non-Restoring Square Root Algorithm

    "An FPGA Implementation of a Fixed-Point Square Root Operation", Krerk Piromsopa, 2002
    https://www.researchgate.net/publication/2532597_An_FPGA_Implementation_of_a_Fixed-Point_Square_Root_Operation
    """
    q = 0
    r = 0
    for i in reversed(range(width // 2 + width % 2)):
        if (r >= 0):
            r = (r << 2) | ((d >> (i + i)) & 3)
            r = r - ((q << 2) | 1)
        else:
            r = (r << 2) | ((d >> (i + i)) & 3)
            r = r + ((q << 2) | 3)
        if (r >= 0):
            q = (q << 1) | 1
        else:
            q = (q << 1) | 0
    return q


if __name__ == "__main__":
    # verify nrsqrt()
    for width in [8, 16, 32, 18, 25]:
        din = [random.randrange(2 ** width) for _ in range(100)]
        for d in din:
            dout = nrsqrt(d, width)
            golden = floor(sqrt(d))
            assert dout == golden, \
                "dout=nrsqrt(%d, width=%d)=%d, golden=floor(sqrt(%d)=%d" % \
                (d, width, dout, d, golden)
