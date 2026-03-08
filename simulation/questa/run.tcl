# ELE432 - Traffic Light FSM Simulation Script
# Run in Questa: source run.tcl

# Quit any existing simulation
quit -sim

# Create work library
vlib work

# Compile design and testbench
vlog traffic_light_fsm.sv
vlog traffic_light_fsm_tb.sv

# Load testbench as top-level
vsim -voptargs=+acc work.traffic_light_fsm_tb

# Load waveform setup
do wave.do

# Run simulation
run -all
