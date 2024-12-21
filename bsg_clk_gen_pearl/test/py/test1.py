import os
import sys, os
import copy

sys.path.append(os.path.join(os.path.dirname(__file__), "..", "..", "..", "test", "py"))
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "..", "..", "py"))
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "..", "test", "py"))
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "..", "py"))

from bsg_chip_pkg import BsgClkGenPearlPkg
from bsg_trace_replay import BsgTraceField, BsgTraceStruct, BsgTraceReplayGen


def generate():
    btp = BsgClkGenPearlPkg()
    btr = BsgTraceReplayGen(int(btp.test_rom_payload_width))
    cgp = BsgTraceStruct(
        "bsg_clk_gen_pearl_trace_pkt_s", int(btp.test_rom_payload_width)
    ).add_field("async_disable", 1)

    c1 = copy.deepcopy(cgp)
    c1.async_disable = 0

    c2 = copy.deepcopy(cgp)
    c2.async_disable = 1

    trace = ""
    trace += btr.wait(64)
    trace += btr.send(c1.get_int())
    trace += btr.wait(64)
    trace += btr.send(c2.get_int())
    trace += btr.wait(32)
    trace += btr.send(c1.get_int())
    trace += btr.wait(32)
    trace += btr.send(c2.get_int())
    trace += btr.wait(16)
    trace += btr.send(c1.get_int())
    trace += btr.wait(16)
    trace += btr.done()

    return trace


if __name__ == "__main__":
    trace = generate()

    print(trace)
