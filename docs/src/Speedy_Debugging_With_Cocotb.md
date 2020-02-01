---
author: Yehowshua Immanuel
date: January 17, 2020
geometry: margin=1in
title: Speedy Debugging With Cocotb
header-includes:
  - \hypersetup{colorlinks=true}
---

# Intro
You may find it more useful to check a certain signal at a certain time step in your
simulation without having view the waveform. This can be done with cocotb.

First make sure you have python3 installed

## Ubuntu or Bash for Windows
```bash
$sudo apt install python3 python3-pip
pip3 install cocotb
```

## MacOS
```bash
$brew install python3
$pip3 install cocotb
```

# Running CocoTB
Change into the directory ``python3-cocotb`` and run ``COCOTB_REDUCED_LOG_FMT=1 VCD=true make``.
Cocotb will emit a lot of warnings because there are currently some uninitialized values in the 
MIPS module.

You'll notice in ``MIPS_tb.py``, that we start by toggling clock ad-infinitum, and then the reset is dropped.
The value of ``read_register_2_address`` is printed to the terminal hidden in a lot of warnings.

Finally, we check that ``read_register_2_address`` is equal to ``2`` at the third clock, and then exit
cocotb. If this check fails, cocotb would issue an error - otherwise, cocotb will display ``ERRORS : 0``.

# Viewing the Resulting Waveforms

You can also view waveforms from Cocotb simulations with GTKWave by opening 
the resulting waveform in the directory ``python-cocotb/sim_build/sim.ghw``.

# Disabling Waveform Output
You can also have cocotb disable waveform output by running ``COCOTB_REDUCED_LOG_FMT=1 VCD=false make``.

# Known Limitations for Cocotb
Cocotb cannot currently access the data inside VHDL memories with Python.
I am discussing with the maintainers of Cocotb to see if there is a solution.