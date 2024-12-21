import os
import sys, os
import copy

sys.path.append(os.path.join(os.path.dirname(__file__), "..", "..", "..", "test", "py"))

from bsg_chip_pkg_gen import BsgChipTagClientObject
from bsg_trace_replay import BsgTraceField, BsgTraceStruct, BsgTraceReplayGen


class BsgTagTraceReplayGen(BsgTraceReplayGen):
    def __init__(
        self,
        tag_masters,
        tag_lg_clients,
        tag_lg_width,
        tag_max_payload_width,
        payload_width,
    ):
        super().__init__(payload_width)

        self.tag_masters = tag_masters
        self.tag_lg_clients = tag_lg_clients
        self.tag_lg_width = tag_lg_width
        self.tag_max_payload_width = tag_max_payload_width

        self.bts = (
            BsgTraceStruct("bsg_tag_trace_pkt_s", payload_width)
            .add_field("masters", tag_masters)
            .add_field("client_id", tag_lg_clients)
            .add_field("data_not_reset", 1)
            .add_field("length", tag_lg_width)
            .add_field("data", tag_max_payload_width)
        )

    def set_client(self, client, data):
        metacomment = (
            f"//// writing client ({client.offset}): {client.name} width: {client.width} data: {data}\n"
        )
        ts = copy.deepcopy(self.bts)
        ts.data = data
        ts.length = client.width
        ts.data_not_reset = 1
        ts.client_id = client.offset
        ts.masters = 2**self.tag_masters - 1

        return self.send(ts.get_int(), metacomment)

    def reset_client(self, client):
        if isinstance(client, BsgChipTagClientObject):
            metacomment = (
                f"//// resetting client ({client.offset}): {client.name} width: {client.width}\n"
            )
            ts = copy.deepcopy(self.bts)
            ts.data = 2**client.width - 1
            ts.length = client.width
            ts.data_not_reset = 0
            ts.client_id = client.offset
            ts.masters = 2**self.tag_masters - 1

            return self.send(ts.get_int(), metacomment)

        trace = ""
        for p in client.gen_clients():
            trace += self.reset_client(p)

        return trace

    def reset_master(self):
        metacomment = f"//// resetting tag masters\n"
        ts = copy.deepcopy(self.bts)
        ts.data = 0
        ts.length = 0
        ts.data_not_reset = 0
        ts.client_id = 0
        ts.masters = 2**self.tag_masters - 1

        trace = ""
        trace += self.send(ts.get_int(), metacomment)
        trace += self.wait(self.payload_width)

        return trace

    ## Meta-routines
    # Initializes bsg_clk_gen_pearl to a slow downsampled clock
    def clk_gen_pearl_init(self, pearl):
        trace = ""

        # Select disabled clock
        trace += self.set_client(pearl.sel, 3)

        # Reset oscillator and trigger flops
        trace += self.set_client(pearl.async_reset, 1)

        # Select slowest osc setting ...
        # Must be 0 to avoid X in simulation
        tap_min = 0
        trace += self.set_client(pearl.osc, tap_min)

        # Bring the flops out of reset
        trace += self.set_client(pearl.async_reset, 0)

        # ... And trigger the initial setting
        trace += self.set_client(pearl.osc_trigger, 1)
        trace += self.set_client(pearl.osc_trigger, 0)

        # Now slow everything down
        tap_max = 2**pearl.osc.width - 1
        trace += self.set_client(pearl.osc, tap_max)

        # ... And trigger the initial setting
        trace += self.set_client(pearl.osc_trigger, 1)
        trace += self.set_client(pearl.osc_trigger, 0)

        # Initialize DS
        ds_reseth_val = 0b01
        ds_resetl_val = 0b00
        trace += self.set_client(pearl.ds, ds_reseth_val)
        trace += self.set_client(pearl.ds, ds_resetl_val)

        # Select DS
        trace += self.set_client(pearl.sel, 1)

        # Reset monitor
        trace += self.set_client(pearl.monitor_reset, 1)
        trace += self.set_client(pearl.monitor_reset, 0)

        return trace

    # Initializes bsg_clk_gen_pearl to a new tap or downsample value
    def clk_gen_pearl_tune(self, pearl, tap=None, ds=None):
        trace = ""

        # Set new osc value
        if tap:
            trace += self.set_client(pearl.osc, tap)
            trace += self.set_client(pearl.osc_trigger, 1)
            trace += self.set_client(pearl.osc_trigger, 0)

        # Initialize DS if set
        if ds:
            ds_reseth_val = (ds << 1) | 1
            ds_resetl_val = (ds << 1) | 0
            trace += self.set_client(pearl.ds, ds_reseth_val)
            trace += self.set_client(pearl.ds, ds_resetl_val)

        # Always reset monitor
        trace += self.set_client(pearl.monitor_reset, 1)
        trace += self.set_client(pearl.monitor_reset, 0)

        # Settle the tune
        trace += self.wait(64)

        return trace

    # Initializes a pair bsg_sdr_link_pearls
    def sdr_link_pearl_init(self, pearls):
        if type(pearls) != list:
            pearls = [pearls]

        trace = ""

        for pearl in pearls:
            # disable links in case of disaster
            trace += self.set_client(pearl.link_i_disable, 1)
            trace += self.set_client(pearl.link_o_disable, 1)

        for pearl in pearls:
            # init sdr clients
            trace += self.set_client(pearl.sdr.token_reset, 0)
            trace += self.set_client(pearl.sdr.uplink_reset, 1)
            trace += self.set_client(pearl.sdr.downlink_reset, 1)
            trace += self.set_client(pearl.sdr.downstream_reset, 1)

        for pearl in pearls:
            # perform async token toggle
            trace += self.set_client(pearl.sdr.token_reset, 1)
            trace += self.set_client(pearl.sdr.token_reset, 0)

        for pearl in pearls:
            # de-assert uplink reset
            trace += self.set_client(pearl.sdr.uplink_reset, 0)

        for pearl in pearls:
            # de-assert downlink reset
            trace += self.set_client(pearl.sdr.downlink_reset, 0)

        for pearl in pearls:
            # de-assert downstream reset
            trace += self.set_client(pearl.sdr.downstream_reset, 0)

        return trace

    # Enables a single bsg_sdr_link_pearl
    def sdr_link_pearl_enable(self, pearl):
        trace = ""

        # disable links in case of disaster
        trace += self.set_client(pearl.link_i_disable, 0)
        trace += self.set_client(pearl.link_o_disable, 0)

        return trace
