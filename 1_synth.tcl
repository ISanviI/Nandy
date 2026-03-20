# Synthesis to produce a gate-level netlist from RTL (Register Transfer Level) Verilog code.
# Run as "yosys -s 1_synth.tcl" (script file) or "yosys -p 'script 1_synth.tcl'" (pass command string)

# Technology (Foundry or PDK specific) related cell definitions are available in "libs.ref" (Silicon Implementation Data - gate Delays, Drive Strength, Power, Area) and rules for EDA tools in "libs.tech" (Tool Integration Layer) file.
# (libs.tech/
#  ├── magic/
#  ├── netgen/
#  ├── ngspice/
#  ├── klayout/
#  ├── openlane/
#  ├── qflow/
# )

# Read SKY130 standard cell liberty file
read_liberty -lib ~/.ciel/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# Read all RTL files
read_verilog system_top.v
read_verilog basic.v
read_verilog alu.v
read_verilog cpu.v
read_verilog cpu_arbiter.v
read_verilog multiply.v
read_verilog divide.v

# Set top module
hierarchy -check -top system_top

# Convert processes (always blocks) to logic
proc

# Optimize
opt

# Convert high-level constructs to simple logic
fsm
opt

# Memory handling (if any reg arrays exist, into flip flops or RAMs)
memory
opt

# Technology mapping to standard cells (Replace generic logic with specific lower level cells from the library)
techmap

# Map flip flops
dfflibmap -liberty ~/.ciel/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# Map combinational logic
abc -liberty ~/.ciel/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# Clean unused cells
clean

# Write synthesized netlist
write_verilog synth_netlist.v

# Show the schematic diagram
# read_verilog synth_netlist.v
# show -format ps
# dot -Tpng system_top.dot -o system_top.png (not in yosys shell, run in terminal)

# Command to start mounted Docker Container while working in "~/Documents/Applications/OpenLane" directory (where OpenLane is cloned and PDKs are stored)
# >> make mount
#       OR
# >> docker run -it \
#   -v $PWD:/openlane \
#   -e PDK_ROOT=/openlane/pdks \
#   -e PDK=sky130A \
#   ghcr.io/the-openroad-project/openlane:latest

# Command for RTL to GDS II in OpenLane
# flow.tcl -design spm
# >> ls Applications/OpenLane/designs/spm/runs/RUN_2026.03.20_15.50.57/results/final
# -- def  gds  lef  lib  mag  maglef  sdc  sdf  spef  spi  verilog
