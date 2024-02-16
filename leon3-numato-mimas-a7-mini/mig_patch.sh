echo "#### Generate MIG Patch ####" >> vivado/leon3_vivado.tcl
echo "set_property target_language verilog [current_project]" >> vivado/leon3_vivado.tcl
echo "import_ip -files vivado/mig.xci -name mig" >> vivado/leon3_vivado.tcl
echo "#upgrade_ip [get_ips mig]" >> vivado/leon3_vivado.tcl
echo "generate_target  all [get_files ./vivado/leon3-numato-mimas-a7-mini/leon3-numato-mimas-a7-mini.srcs/sources_1/ip/mig/mig.xci] -force " >> vivado/leon3_vivado.tcl



