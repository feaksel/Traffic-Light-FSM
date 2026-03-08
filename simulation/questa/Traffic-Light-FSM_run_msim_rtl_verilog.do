transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+C:/Users/furka/Traffic-FSM {C:/Users/furka/Traffic-FSM/traffic_light_fsm.sv}

vlog -sv -work work +incdir+C:/Users/furka/Traffic-FSM/simulation/questa {C:/Users/furka/Traffic-FSM/simulation/questa/traffic_light_fsm_tb.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"  traffic_light_fsm_tb

add wave *
view structure
view signals
run 300 ns
