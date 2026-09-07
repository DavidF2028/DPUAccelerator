set HW_DIR "../../platform/hw/sdt"
connect
targets -set -filter {name =~ "PSU"}
fpga "$HW_DIR/DPU_Block_wrapper.bit"
after 1000
source "$HW_DIR/psu_init.tcl"
psu_init
after 1000
# Read PS register used during hardware bring-up/debugging
mrd 0xFD080030
psu_ps_pl_isolation_removal
after 1000
psu_ps_pl_reset_config
after 1000