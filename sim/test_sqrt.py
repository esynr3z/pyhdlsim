#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""Tests for sqrt module"""


import pytest
from sim import Simulator, CliArgs, path_join, write_memfile
import random
import sys
sys.path.append('../src/beh')
from sqrt import nrsqrt


def create_sim(cwd, simtool, gui, defines):
    sim = Simulator(name=simtool, gui=gui, cwd=cwd)
    sim.incdirs += ["../src/tb", "../src/rtl", cwd]
    sim.sources += ["../src/rtl/sqrt.v", "../src/tb/tb_sqrt.sv"]
    sim.defines += defines
    sim.top = "tb_sqrt"
    return sim


@pytest.fixture(params=[[], ['DIN_W=16'], ['DIN_W=18'], ['DIN_W=25'], ['DIN_W=32']])
def defines(request):
    return request.param


@pytest.fixture
def simtool(pytestconfig):
    return pytestconfig.getoption("sim")


def test_sv(tmpdir, defines, simtool, gui=False, pytest_run=True):
    sim = create_sim(tmpdir, simtool, gui, defines)
    sim.setup()
    sim.run()
    if pytest_run:
        assert sim.is_passed


def test_py(tmpdir, defines, simtool, gui=False, pytest_run=True):
    # prepare simulator
    sim = create_sim(tmpdir, simtool, gui, defines)
    sim.setup()

    # prepare model data
    try:
        din_width = int(sim.get_define('DIN_W'))
    except TypeError:
        din_width = 32
    iterations = 100
    stimuli = [random.randrange(2 ** din_width) for _ in range(iterations)]
    golden = [nrsqrt(d, din_width) for d in stimuli]
    write_memfile(path_join(tmpdir, 'stimuli.mem'), stimuli)
    write_memfile(path_join(tmpdir, 'golden.mem'), golden)
    sim.defines += ['ITER_N=%d' % iterations]
    sim.defines += ['PYMODEL', 'PYMODEL_STIMULI="stimuli.mem"', 'PYMODEL_GOLDEN="golden.mem"']

    # run simulation
    sim.run()
    if pytest_run:
        assert sim.is_passed


#@pytest.mark.skip(reason="Test is too slow")
def test_slow(tmpdir, defines, simtool, gui=False, pytest_run=True):
    sim = create_sim(tmpdir, simtool, gui, defines)
    sim.defines += ['ITER_N=500000']
    sim.setup()
    sim.run()
    if pytest_run:
        assert sim.is_passed


if __name__ == '__main__':
    # run script with key -h to see help
    args = CliArgs().parse()
    try:
        globals()[args.test](tmpdir='work',
                             simtool=args.simtool,
                             gui=args.gui,
                             defines=args.defines,
                             pytest_run=False)
    except KeyError:
        print("There is no test with name '%s'!" % args.test)
