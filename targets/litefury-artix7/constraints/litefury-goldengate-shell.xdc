# LiteFury Artix-7 GoldenGate shell constraints
#
# This target pack treats GoldenGate as an AXI-Lite peripheral behind the
# LiteFury PCIe/XDMA shell. The shell or block design owns physical PCIe,
# DDR, SPI, and clock pin constraints. This file constrains the cleanroom
# GoldenGate wrapper boundary.
#
# Proven board: LiteFury Artix-7 XC7A100T-L2FGG484E

create_clock -name s_axi_aclk -period 8.000 [get_ports s_axi_aclk]

set reset_cells [get_cells -quiet -hierarchical *areset*]
if {[llength $reset_cells] > 0} {
  set_property ASYNC_REG TRUE $reset_cells
}

# Fill these in only in a full board design that instantiates the PCIe/XDMA
# shell directly rather than importing this wrapper as IP:
#
# set_property PACKAGE_PIN <pin> [get_ports pcie_rxp[0]]
# set_property PACKAGE_PIN <pin> [get_ports pcie_txp[0]]
# set_property PACKAGE_PIN <pin> [get_ports sys_clk_p]
# set_property PACKAGE_PIN <pin> [get_ports sys_rst_n]
