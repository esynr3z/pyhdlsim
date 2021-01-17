# Example of Python and PyTest powered workflow for a HDL simulation

![PyTest Icarus Status](https://github.com/esynr3z/pyhdlsim/workflows/pytest-icarus/badge.svg)
![PyTest Modelsim Status](https://github.com/esynr3z/pyhdlsim/workflows/pytest-modelsim/badge.svg)

**Detailed description can be found on Russian at [Habr.com](https://habr.com/ru/post/537704)**

## Repository structure

```bash
$ tree -a -I .git
.
├── .github
│   └── workflows # Github Actions
│       ├── icarus-test.yml # run all tests with Icarus Verilog on every push
│       └── modelsim-test.yml # run all tests with Modelsim on every push
├── .gitignore
├── LICENSE.txt
├── README.md
├── sim # simulation scripts
│   ├── conftest.py
│   ├── sim.py
│   └── test_sqrt.py
└── src # sources
    ├── beh # behavioral models
    │   └── sqrt.py
    ├── rtl # synthesizable HDL
    │   └── sqrt.v
    └── tb # testbenches
        └── tb_sqrt.sv
```

```sim.py``` is the simulation core file, which contains wrappers for Icarus Verlog, Modelsim and Vivado simulator.

## Description

Long story short, I simply wanted to replace my Bash scripts I usually use to simulate HDL. And actually I did it and earned even more that expected.

This is a simple example of how Python and Pytest can be combined to create a flexible and easy to support environment to simulate and test HDL.

Main idea is to wrap several simulators like Icarus Verilog, Modelsim or Vivado Simulator with one python class ```Simulator```, add class ```CliArgs``` to parse command line arguments, implement some frequently used utility functions. And then simply use this things in any other Python script, so you will be able to:

* to run single selected test (e.g. ```test_sv```) with GUI

```
./test_sqrt -t test_sv
```

* to run single test in batch mode without GUI

```
./test_sqrt -t test_sv -b
```

* to run single test in a specified simmulator

```
./test_sqrt -t test_sv -s modelsim
```

* to run single test with additional defines

```
./test_sqrt -t test_sv -d DIN_W=32 ITER_N=1000
```

* to run all tests available

```
pytest -v
```

* to run all tests in a parallel way (pytest-xdist must be installed)

```
pytest -v -n 4
```

* to run all tests in a different simulator

```
pytest -v --sim vivado
```

And as a bonus this workflow is easy to organize CI. Examples of Github Actions are in ```.github/workflows```.

