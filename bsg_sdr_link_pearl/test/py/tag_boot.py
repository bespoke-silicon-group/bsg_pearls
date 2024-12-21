import os
import sys, os
import copy

sys.path.append(os.path.join(os.path.dirname(__file__), "..", "..", "..", "test", "py"))
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "..", "..", "py"))
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "..", "test", "py"))
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "..", "py"))

from bsg_chip_pkg import BsgSdrLinkPearlPkg
from bsg_trace_replay import BsgTraceField, BsgTraceStruct, BsgTraceReplayGen
from bsg_tag_trace_replay import BsgTagTraceReplayGen

def generate():
    btp = BsgSdrLinkPearlPkg()
    btr = BsgTagTraceReplayGen(
        int(btp.tag_masters),
        int(btp.tag_lg_clients),
        int(btp.tag_lg_width),
        int(btp.tag_max_payload_width),
        int(btp.tag_rom_payload_width),
    )

    trace = ""
    trace += btr.reset_master()
    trace += btr.reset_client(btp.sdr_link)
    trace += btr.reset_client(btp.gateway)

    trace += btr.sdr_link_pearl_init([btp.sdr_link, btp.gateway])
    trace += btr.sdr_link_pearl_enable(btp.sdr_link)
    trace += btr.sdr_link_pearl_enable(btp.gateway)

    return trace


if __name__ == "__main__":
    trace = generate()

    print(trace)
