import os
import sys, os
import copy

sys.path.append(os.path.join(os.path.dirname(__file__), "..", "..", "..", "test", "py"))
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "..", "..", "py"))
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "..", "test", "py"))
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "..", "py"))

from bsg_chip_pkg import BsgSdrLinkPearlPkg
from bsg_trace_replay import BsgTraceField, BsgTraceStruct, BsgTraceReplayGen


def generate():
    btp = BsgSdrLinkPearlPkg()
    btr = BsgTraceReplayGen(int(btp.test_rom_payload_width))
    cgp = BsgTraceStruct(
        "bsg_sdr_link_trace_pkt_s", int(btp.test_rom_payload_width)
    )

    trace = ""
    trace += btr.wait(16)
    trace += btr.done()

    return trace


if __name__ == "__main__":
    trace = generate()

    print(trace)
