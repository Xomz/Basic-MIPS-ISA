import cocotb
from cocotb.triggers import Timer, ClockCycles, FallingEdge, RisingEdge
from cocotb.clock import Clock


@cocotb.test()
def test_MIPS(dut):
    DEBUG_HEX = lambda x : dut._log.info(f"{x._name}={x.value.hex}")
    DEBUG_HEX = lambda x : dut._log.info(f"{x._name}={x.value.integer}")

    #define the clock period in ns
    T = 50

    #toggle the clock for the duration of the simulation
    cocotb.fork(Clock(dut.CLOCK,T,'ns').start())
    yield cocotb.triggers.ClockCycles(dut.CLOCK, 1)

    #perform reset
    dut.CRESET = 1
    yield cocotb.triggers.ClockCycles(dut.CLOCK, 2)
    dut.CRESET = 0
    yield cocotb.triggers.ClockCycles(dut.CLOCK, 1)

    #prints the hex value of read_register_2_address
    DEBUG_HEX(dut.read_register_2_address)

    #an example of a test
    assert dut.read_register_2_address == 2