help:
	@echo -e "Select operation to perform. Type 'make' followed by the name of the operation."
	@echo
#	@echo -e "Available operations:"
#	@echo -e "doxygen             - run the doxygen tool on the aoOCS project."
#	@echo -e "                      Doxverilog version required."
#	@echo -e "control_osd         - generate ./rtl/control_osd.mif"
#	@echo -e "sd_disk             - generate SD disk image containing ROMs and ADFs."
#	@echo -e "                      The disk image should be written to a SD card starting at offset 0."
#	@echo -e "spec_extract        - generate the specification.odt file from the Doxygen HTML docs."
#	@echo -e "vga_to_png          - extract VGA dump file to a set of PNG frame images."
	@echo -e "de2_115_ltm  - synthesise Holosynth for the DE2-115 board with LTM."
	@echo -e "de2_115_ltm_nios2  - synthesise Holosynth nios2 for the DE2-115 board with LTM."
	@echo -e "clean               - clean all."
	@echo
	@exit 0

#doxygen: ./doc/doxygen/doxygen.cfg
#ifndef DOXVERILOG
#	@echo "DOXVERILOG environment variable not set. Set it to a Doxverilog executable."
#	@exit 1
#endif
#	$(DOXVERILOG) ./doc/doxygen/doxygen.cfg


de2_115_ltm:
	mkdir -p ./tmp/de2_115_ltm
	cp ./rtl/verilog/Altera/*.v ./tmp/de2_115_ltm
	cp ./rtl/verilog/board/terasic/common/*.v ./tmp/de2_115_ltm
	cp ./rtl/verilog/board/terasic/common/*.sv ./tmp/de2_115_ltm
	cp ./rtl/verilog/board/terasic/de2_115/*.v ./tmp/de2_115_ltm
	cp ./rtl/verilog/common/*.v ./tmp/de2_115_ltm
	cp ./rtl/verilog/common/display/*.v ./tmp/de2_115_ltm
	cp ./rtl/verilog/common/display/*.hex ./tmp/de2_115_ltm
	cp ./rtl/verilog/common/midi/*.v ./tmp/de2_115_ltm
	cp ./rtl/verilog/common/midi/*.sv ./tmp/de2_115_ltm
	cp ./rtl/verilog/common/synth/*.v ./tmp/de2_115_ltm
	cp ./rtl/verilog/common/synth/*.sv ./tmp/de2_115_ltm
	cp ./rtl/verilog/common/synth/*.mif ./tmp/de2_115_ltm
	cp ./syn/Altera/terasic/de2_115_ltm/*.qpf ./tmp/de2_115_ltm
	cp ./syn/Altera/terasic/de2_115_ltm/*.qsf ./tmp/de2_115_ltm
	cp ./syn/Altera/terasic/de2_115_ltm/*.sdc ./tmp/de2_115_ltm
	cd ./tmp/de2_115_ltm && quartus_sh --flow compile Holosynth

de2_115_ltm_nios2:
	mkdir -p ./tmp/de2_115_ltm
	cp ./rtl/verilog/Altera/*.v ./tmp/de2_115_ltm
	cp ./rtl/verilog/board/terasic/common/*.v ./tmp/de2_115_ltm
	cp ./rtl/verilog/board/terasic/common/*.sv ./tmp/de2_115_ltm
	cp ./rtl/verilog/board/terasic/de2_115/*.v ./tmp/de2_115_ltm
	cp ./rtl/verilog/board/terasic/de2_115/*.qsys ./tmp/de2_115_ltm
	cp ./rtl/verilog/common/*.v ./tmp/de2_115_ltm
	cp ./rtl/verilog/common/display/*.v ./tmp/de2_115_ltm
	cp ./rtl/verilog/common/display/*.hex ./tmp/de2_115_ltm
	cp ./rtl/verilog/common/midi/*.v ./tmp/de2_115_ltm
	cp ./rtl/verilog/common/midi/*.sv ./tmp/de2_115_ltm
	cp ./rtl/verilog/common/synth/*.v ./tmp/de2_115_ltm
	cp ./rtl/verilog/common/synth/*.sv ./tmp/de2_115_ltm
	cp ./rtl/verilog/common/synth/*.mif ./tmp/de2_115_ltm
	cp ./syn/Altera/terasic/de2_115_ltm/*.qpf ./tmp/de2_115_ltm
	cp ./syn/Altera/terasic/de2_115_ltm/*.qsf ./tmp/de2_115_ltm
	cp ./syn/Altera/terasic/de2_115_ltm/*.sdc ./tmp/de2_115_ltm
	cd ./tmp/de2_115_ltm && quartus_sh --flow compile Holosynth

clean:
	rm -R -f ./tmp/*
