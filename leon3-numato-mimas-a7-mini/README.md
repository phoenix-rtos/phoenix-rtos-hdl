# [LEON3](https://www.gaisler.com/index.php/products/processors/leon3) on Numato Lab's [Mimas A7 Mini](https://numato.com/product/mimas-a7-mini-fpga-development-board/)

This is a LEON3 design meant to work on Numato Lab's Mimas A7 Mini board.

## Building

This design was written with Xilinx Vivado 2020.2 in mind, but other versions might work too (probably after some slight modifications to the TCL scripts and other adjustments to account for differences between Xilinx MIG memory controller generator versions).

You will also need a copy of the GPL version of GRLIB, available for download [here](https://www.gaisler.com/index.php/downloads/grlib) (only the latest version). This design uses `grlib-gpl-2023.2-b4383`, which you can find [here](https://github.com/TUT-ASI/leon3-grlib-gpl-mirror), but it might also work with newer versions. GRLIB location should be specified in the Makefile.

GRLIB's build system (the one used for LEON3 designs in particular) is far from trivial, which, coupled with the desire to keep this design's files separate from GRLIB itself, resulted in a couple of workarounds present mostly in the `project specific targets` section of the Makefile, but also in the form of standalone scripts.

To build this project, first call
```
make xconfig
```
to bring up GRLIB's version of xconfig. Click `Save and Exit` immediately, then on `OK` to exit. This uses the config stored in `.config` to generate several files, most importantly `config.vhd` used later in the build process.

Next, run
```
make vivado
```
and exit after about one second (before Vivado manages to do anything) - this will generate TCL script files in the `vivado/` directory, which can then be patched by running
```
make .bin_file_getting_generated
./mig_patch.sh
```
to make Vivado generate not only the configuration RAM file (`*.bit`), but also the non-volatile configuration file (`*.bin`), as well as to make Xilinx MIG work.

Now you can build the project for real by running
```
make vivado
```
and letting it finish, which can take several minutes (about 10 minutes on a reasonably recent, mid-range laptop).

Use
```
make upload-cram
```
to upload the generated bitstream to configuration RAM (useful for debugging the FPGA design itself), or
```
make upload-crom
```
to upload it to the onboard flash configuration memory (`make upload-crom` requires MIT-licensed [`bscan_spi_xc7a35t.bit`](https://github.com/quartiq/bscan_spi_bitstreams/blob/master/bscan_spi_xc7a35t.bit) to be present in `board_files/`).

## Testing

After succesfully building and uploading the bitstream, you can connect to LEON3's UART3 via P4, one of the Mimas' GPIO connectors. Pin 7 of the connector (pad E15 of the FPGA) is TX and pin 9 (pad F14) is RX (TX and RX from LEON3's point of view).

You can use picocom to test if everything is working correctly.
```
picocom --imap lfcrlf -b 115200 -r -l <serial_port_path>

```
Soft-resetting the core by pressing BTN0 should print `Bootloader` to the serial port, mashing the keyboard for a while should result in the bootloader complaining (`Invalid magic: wxyz`), just make sure to reset it afterwards if you want to use the bootloader, to make sure nothing is left in the buffer.

Another simple test can be performed by uploading a single instruction using the bootloader, the bootloader will accept it, store it in CPU memory (implemented with FPGA block RAM), jump to that adress and execute the instruction - a jump back to the bootloader code. With picocom, you can do that by pressing `Ctrl+a`, then `Ctrl+w`, pasting in `deadbeef000000023100000081c0200001000000` (32 bit magic number, 32 bit length, memory address to store it in, a jump back to the bootloader (with a trailing NOP to fill the SPARC delay slot)):

```
Bootloader

*** hex: deadbeef000000023100000081c0200001000000
*** wrote 20 bytes ***
Image loaded
Bootloader
```

## Design Description

Since the main use case for this design was to have something to run the LEON3 port of Phoenix-RTOS against, which was developed on the [GR716-MINI Evaluation Board](https://www.gaisler.com/index.php/products/boards/gr716-boards), this design shares some similarities with the GR716A, meaning those periphereals which are included are located in the same memory space and those which are not included have been filled with dummy AHB/APB bus slaves to handle reads and writes without crashing.

See `leon3.vhd` for more details, but here's a quick rundown of what exactly is included:
 - the LEON3 core itself
 - IRQAMP interrupt controller at address `0x80002000`
 - GPTIMER general purpose timer at address `0x80003000`
 - APBUART UART controller at address `0x80302000` (aka UART2)
 - APBUART UART controller at address `0x80303000` (aka UART3)
 - SPICTRL SPI controller at address `0x80309000`
 - AHBROM at address `0x00000000` containing the bootloader
 - 256 MiB of AHB-attached RAM at address `0x40000000` (the entirety of Mimas A7 Mini's DDR3 memory)

## License

This project uses the GPL version of GRLIB and as such is also GPL-licensed, see `LICENSE`.

Additional information about modifications is provided in relevant files themselves.
