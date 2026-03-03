# Run as "yosys -s 1_synth.tcl" (script file) or "yosys -p 'script 1_synth.tcl'" (pass command string)

# Technology (Foundry or PDK specific) related cell definitions are available in "libs.ref" (Silicon Implementation Data - gate Delays, Drive Strenght, Power, Area) and rules for EDA tools in "libs.tech" (Tool Integration Layer) file.
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