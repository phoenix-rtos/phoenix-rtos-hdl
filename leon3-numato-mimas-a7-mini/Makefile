include .config

GRLIB=../../grlib-gpl-2023.2-b4283
GRLIB_CONFIG 	?= ./grlib_config.vhd

TOP=leon3
BOARD=numato-mimas-a7-mini-xc7a35t
DESIGN=leon3-numato-mimas-a7-mini
include ./board_files/Makefile.inc
DEVICE=$(PART)-$(PACKAGE)$(SPEED)
UCF=$(TOP).ucf
UCF_PLANAHEAD=$(UCF)
XDC = board_files/mimas-leon3.xdc
XDC += board_files/mig/mig.xdc

QSF=$boards_files/$(TOP).qsf
EFFORT=high
XSTOPT=-uc leon3.xcf
SYNPOPT="set_option -pipe 1; set_option -retiming 1; set_option -write_apr_constraint 0"

VHDLSYNFILES =
VHDLSYNFILES += board_files/ahb2mig_7series.vhd
VHDLSYNFILES += board_files/clockers_mig.vhdl
VHDLSYNFILES += board_files/clockers_clkgen.vhdl 
VHDLSYNFILES += config.vhd apbnone.vhd apbnone_grclkgate.vhd apbnone_pll.vhd ahbrom.vhd leon3.vhd
VHDLSIMFILES = testbench.vhd

SIMTOP=testbench
FDCFILE=board_files/default.fdc
BITGEN=board_files/default.ut
CLEAN=soft-clean

TECHLIBS = secureip unisim

LIBSKIP = core1553bbc core1553brm core1553brt gr1553 corePCIF \
	tmtc openchip ihp usbhc spw esa fmf spansion gsi cypress \
	hynix micron

DIRSKIP = b1553 pci/pcif leon2 leon2ft crypto satcan pci leon3ft ambatest can \
	usb grusbhc spacewire ascs slink hcan \
	leon4v0 l2cache pwm gr1553b iommu subsys grrm grdmac nand i2c

FILESKIP = grcan.vhd

# Options used during compilation
VCOMOPT=-explicit -O0

VSIMOPT+= -t fs -voptargs="+acc -nowarn 1" 
VSIMOPT+= -L secureip_ver -L xilinxcorelib_ver -L unisims_ver glbl
VSIMOPT+= -gUSE_MIG_INTERFACE_MODEL=false

# GHDL does not like the unisim clkgen for some reason
GHDLRUNOPT+= -gclktech=0

# Simulator switches
ifeq ("$(GRLIB_SIMULATOR)","ALDEC")
VSIMOPT+= +access +w -voptargs="+acc -nowarn 1" +notimingchecks
else
VSIMOPT+= -voptargs="+acc -nowarn 1" +notimingchecks
endif

# Simulation scripts
VSIMOPT+= -do wave.do
VSIMOPT+= -do $(GRLIB)/bin/runvsim.do

# Toplevel
VSIMOPT+= $(SIMTOP)

include $(GRLIB)/bin/Makefile
include $(GRLIB)/software/leon3/Makefile

# new
VIVADO_IMPL_STRATEGY=Performance_ExplorePostRoutePhysOpt

##################  project specific targets ##########################

upload-cram: $(TOP).bit
	sudo openocd -f board_files/numato_mimasa7mini.cfg -c "init" -c "pld load 0 ./$(TOP).bit" -c "shutdown"

.bin_file_getting_generated: vivado/$(TOP)_vivado_run.tcl
	sed -i '/mask_file/a set_property steps.write_bitstream.args.bin_file true [get_runs impl_1]' vivado/$(TOP)_vivado_run.tcl
	touch .bin_file_getting_generated

upload-crom: .bin_file_getting_generated
	sudo openocd -f ./board_files/numato_mimasa7mini.cfg -c "init" -c "jtagspi_init 0 ./board_files/bscan_spi_xc7a35t.bit" -c "jtagspi_program ./vivado/$(DESIGN)/$(DESIGN).runs/impl_1/$(TOP).bin 0" -c "shutdown"

program:
	sudo openocd -f ./board_files/numato_mimasa7mini.cfg -c "init" -c "pld load 0 ./vivado/$(DESIGN)/$(DESIGN).runs/impl_1/$(TOP).bit" -c "shutdown"
copy-mig:
	cp -f board_files/mig/mig.prj vivado/mig.prj
	cp -f board_files/mig/mig.xci vivado/mig.xci
	cp -f board_files/mig/mig.xdc vivado/mig.xdc

vivado-launch: copy-mig
vivado: copy-mig

clean-xconfig: 
	rm -f lconfig.tk
	rm -f main.tk
	rm -f tkgen.o
	rm -f tkconfig.h
vivprog:
	vivado -mode tcl -source bitfile/doprog.tcl

vivrom:
	vivado -mode tcl -source bitfile/dorom.tcl

vivado-run:
	vivado ./vivado/$(DESIGN)/$(DESIGN).xpr

vivado-d:
	cat vivado/$(DESIGN)/$(DESIGN).runs/synth_1/runme.log
	cat vivado/$(DESIGN)/$(DESIGN).runs/impl_1/runme.log

