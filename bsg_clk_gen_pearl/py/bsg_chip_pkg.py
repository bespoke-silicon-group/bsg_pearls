import os
import sys, os

sys.path.append(os.path.join(os.path.dirname(__file__), "..", "..", "py"))

from bsg_chip_pkg_gen import (
    BsgChipObject,
    BsgChipPkgObject,
    BsgChipImportObject,
    BsgChipParamObject,
    BsgChipTagClientGroupObject,
    BsgChipTagClientObject,
)


class BsgClkGenPearlPkg(BsgChipPkgObject):
    def __init__(self):
        super().__init__(name="bsg_clk_gen_pearl", struct="bsg_chip")

        # Tag setup
        self.add(BsgChipParamObject("tag_masters", 2))
        self.add(BsgChipParamObject("tag_els", 1024))
        self.add(BsgChipParamObject("tag_max_payload_width", 12))
        self.add(
            BsgChipParamObject(
                "tag_lg_width", BsgChipObject.clog2(int(self.tag_max_payload_width))
            )
        )
        self.add(
            BsgChipParamObject("tag_lg_clients", BsgChipObject.clog2(int(self.tag_els)))
        )
        self.add(BsgChipParamObject("tag_rom_str", '"TAG_TRACE"'))
        self.add(BsgChipParamObject("tag_rom_payload_width", 32))
        self.add(BsgChipParamObject("tag_rom_addr_width", 15))
        self.add(
            BsgChipParamObject(
                "tag_rom_data_width", int(self.tag_rom_payload_width) + 4
            )
        )
        self.add(BsgChipParamObject("test_rom_str", '"TEST_TRACE"'))
        self.add(BsgChipParamObject("test_rom_payload_width", 128))
        self.add(BsgChipParamObject("test_rom_addr_width", 15))
        self.add(
            BsgChipParamObject(
                "test_rom_data_width", int(self.test_rom_payload_width) + 4
            )
        )
        self.add(BsgChipParamObject("trace_str", '"bsg_trace"'))

        # DUT setup
        self.add(BsgChipParamObject("watcher_tolerance", 0))
        self.add(BsgChipParamObject("ds_width", 4))
        self.add(BsgChipParamObject("num_taps", 64))
        self.add(BsgChipParamObject("ctl_width", BsgChipObject.clog2(int(self.num_taps))))

        # DUT clients
        self.add(
            BsgChipTagClientGroupObject("bsg_clk_gen_pearl_tag_lines", "clk_gen")
            .add(BsgChipTagClientObject("async_reset", 1))
            .add(BsgChipTagClientObject("osc", int(self.ctl_width)))
            .add(BsgChipTagClientObject("osc_trigger", 1))
            .add(BsgChipTagClientObject("ds", int(self.ds_width)+1))
            .add(BsgChipTagClientObject("sel", 2))
            .add(BsgChipTagClientObject("monitor_reset", 1))
        )

        # Gateway clients
        self.add(
            BsgChipTagClientGroupObject("bsg_gateway_tag_lines", "gateway")
            .add(BsgChipTagClientObject("unused", 1))
        )

        # MISC setup
        self.add(BsgChipParamObject("asic_num_clocks", 1))
        self.add(BsgChipParamObject("asic_tag_local_els", int(self.clk_gen.width)))
        self.add(BsgChipParamObject("asic_tag_node_id_offset", 0))
        self.add(BsgChipParamObject("gateway_tag_local_els", 1))
        self.add(BsgChipParamObject("gateway_tag_node_id_offset", 0))


if __name__ == "__main__":
    pkg = BsgClkGenPearlPkg()

    print(pkg.get_pkg())
