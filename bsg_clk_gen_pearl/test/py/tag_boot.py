import os
import sys, os
import copy

sys.path.append(os.path.join(os.path.dirname(__file__), "..", "..", "..", "test", "py"))
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "..", "..", "py"))
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "..", "test", "py"))
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "..", "py"))

from bsg_chip_pkg import BsgClkGenPearlPkg
from bsg_trace_replay import BsgTraceField, BsgTraceStruct, BsgTraceReplayGen
from bsg_tag_trace_replay import BsgTagTraceReplayGen

def generate():
    btp = BsgClkGenPearlPkg()
    btr = BsgTagTraceReplayGen(
        int(btp.tag_masters),
        int(btp.tag_lg_clients),
        int(btp.tag_lg_width),
        int(btp.tag_max_payload_width),
        int(btp.tag_rom_payload_width),
    )

    trace = ""
    trace += btr.reset_master()
    trace += btr.reset_client(btp.clk_gen)

    trace += btr.set_client(btp.clk_gen.sel, 2)

    trace += btr.set_client(btp.clk_gen.async_reset, 1)

    trace += btr.set_client(btp.clk_gen.osc, 0)
    trace += btr.set_client(btp.clk_gen.osc_trigger, 0)

    trace += btr.set_client(btp.clk_gen.async_reset, 0)

    trace += btr.set_client(btp.clk_gen.osc_trigger, 1)
    trace += btr.set_client(btp.clk_gen.osc_trigger, 0)

    trace += btr.set_client(btp.clk_gen.ds, 0b01)
    trace += btr.set_client(btp.clk_gen.ds, 0b00)

    trace += btr.set_client(btp.clk_gen.sel, 1)

    for i in range(int(btp.num_taps)):
        trace += btr.set_client(btp.clk_gen.osc, i)

        trace += btr.set_client(btp.clk_gen.osc_trigger, 1)
        trace += btr.set_client(btp.clk_gen.osc_trigger, 0)

        trace += btr.set_client(btp.clk_gen.monitor_reset, 1)
        trace += btr.set_client(btp.clk_gen.monitor_reset, 0)

        trace += btr.wait(64)

    trace += btr.done()

    return trace


if __name__ == "__main__":
    trace = generate()

    print(trace)
