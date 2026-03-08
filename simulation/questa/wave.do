# ELE432 - Traffic Light FSM Waveform Setup

# Inputs
add wave -divider "INPUTS"
add wave -label "clk"   /traffic_light_fsm_tb/clk
add wave -label "reset" /traffic_light_fsm_tb/reset
add wave -label "TAORB" /traffic_light_fsm_tb/TAORB

# Internal State
add wave -divider "FSM INTERNALS"
add wave -label "state" /traffic_light_fsm_tb/DUT/current_state
add wave -label "timer" -radix unsigned /traffic_light_fsm_tb/DUT/timer

# Outputs
add wave -divider "OUTPUTS"
add wave -label "LA" /traffic_light_fsm_tb/LA
add wave -label "LB" /traffic_light_fsm_tb/LB

# Zoom to fit
wave zoom full
