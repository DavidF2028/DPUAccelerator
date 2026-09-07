vlib work
vmap work work
vlog *.sv
vsim -voptargs=+acc work.DPU_Top_tb
add wave *
run -all