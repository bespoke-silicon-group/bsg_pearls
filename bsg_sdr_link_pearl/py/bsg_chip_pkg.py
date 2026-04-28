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


class BsgChipPkg(BsgChipPkgObject):
    def __init__(self):
        super().__init__(name="toplevel_tag_name", struct="bsg_chip")

        # Add package imports
        self.add(BsgChipImportObject("bsg_link"))

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
        self.add(BsgChipParamObject("sdr_data_width", 8))
        self.add(BsgChipParamObject("sdr_lg_fifo_depth", 3))
        self.add(BsgChipParamObject("sdr_lg_credit_to_token_decimation", 0))
        self.add(BsgChipParamObject("core_data_width", 16))

        # Assembly
        self.add(
            BsgChipTagClientGroupObject("bsg_sdr_link_pearl_tag_lines", "sdr_link")
            .add(BsgChipTagClientGroupObject("bsg_link_sdr_tag_lines", "sdr", external=True)
                 .add(BsgChipTagClientObject("uplink_reset", 1))
                 .add(BsgChipTagClientObject("downlink_reset", 1))
                 .add(BsgChipTagClientObject("downstream_reset", 1))
                 .add(BsgChipTagClientObject("token_reset", 1))
                 )
            .add(BsgChipTagClientObject("link_i_disable", 1))
            .add(BsgChipTagClientObject("link_o_disable", 1))
        )

        self.add(
            BsgChipTagClientGroupObject("bsg_gateway_tag_lines", "gateway")
            .add(BsgChipTagClientGroupObject("bsg_link_sdr_tag_lines", "sdr", external=True)
                 .add(BsgChipTagClientObject("uplink_reset", 1))
                 .add(BsgChipTagClientObject("downlink_reset", 1))
                 .add(BsgChipTagClientObject("downstream_reset", 1))
                 .add(BsgChipTagClientObject("token_reset", 1))
                 )
            .add(BsgChipTagClientObject("link_i_disable", 1))
            .add(BsgChipTagClientObject("link_o_disable", 1))
        )

        # MISC setup
        self.add(BsgChipParamObject("asic_num_clocks", 1))
        self.add(BsgChipParamObject("asic_tag_local_els", int(self.sdr_link.width)))
        self.add(BsgChipParamObject("asic_tag_node_id_offset", 0))
        self.add(BsgChipParamObject("gateway_tag_local_els", 1))
        self.add(BsgChipParamObject("gateway_tag_node_id_offset", 0))


if __name__ == "__main__":
    pkg = BsgSdrLinkPearlPkg()

    print(pkg.get_pkg())
