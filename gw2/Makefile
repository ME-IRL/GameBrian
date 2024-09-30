TRELLIS?=/usr/share/trellis

TARGET = GameBrian
BOARD ?= ecp5-evn
IN_FREQ = 50
BUILD_DIR = build
DATA = data.bin

## PLLs ##
PLLs = 60 65 70 75 80 100 150 200 250 275
PLL_FILES = $(foreach f,$(PLLs),$(BUILD_DIR)/PLL$f.v)
SV_SOURCES = $(wildcard src/*.sv)
TOP = src/board/$(BOARD).v
SOURCES = $(PLL_FILES) $(TOP) $(SV_SOURCES)

SIM = spi
SIM_VCD = $(foreach f,$(SIM),$(BUILD_DIR)/$f.vcd)

$(BUILD_DIR)/PLL%.v: | $(BUILD_DIR)
	@echo Generating $* MHz PLL...
	@ecppll -n PLL$* \
	--clkin_name   clk_in \
	-i $(IN_FREQ) \
	--clkout0_name clk_out \
	-o $* \
	-f $@ > /dev/null

.PHONY: prog flash data sim clean
.PRECIOUS: $(BUILD_DIR)/$(TARGET).bit $(BUILD_DIR)/$(TARGET).v

# prog2: $(BUILD_DIR)/$(TARGET).svf
# 	# openocd -f ${TRELLIS}/misc/openocd/ecp5-evn.cfg -c "transport select jtag; init; svf $<; exit"
# 	# openocd -f ecp5-evn.cfg -c "transport select jtag; init; svf $<; exit"
# 	openFPGALoader -b ecp5_evn -f build/GameBrian.bit

#$(BUILD_DIR)/%.svf: $(BUILD_DIR)/%.bit ;

prog: $(BUILD_DIR)/$(TARGET).bit
	@echo Programming to SRAM...
	@#ecpprog -S $^
	@openFPGALoader -b ecp5_evn $^

flash: $(BUILD_DIR)/$(TARGET).bit | data
	@echo Programming to flash...
	@#ecpprog $^
	@openFPGALoader -b ecp5_evn -f $^

data: $(DATA)
	@echo Programming data to flash 0x100000...
	@#ecpprog -o 0x100000 $^
	@openFPGALoader -b ecp5_evn -f $^ -o 0x100000

$(BUILD_DIR)/%.bit: $(BUILD_DIR)/%.cfg
	@#ecppack --svf-rowsize 100000 --svf $(BUILD_DIR)/$*.svf $^ $@
	@echo Packing to bitstream...
	@ecppack $^ $@ #--spimode qspi

$(BUILD_DIR)/%.cfg: src/board/$(BOARD).lpf $(BUILD_DIR)/%.json
	@echo Placing and routing using nextpnr...
	@nextpnr-ecp5 --json $(word 2, $^) --lpf $< --textcfg $@ --um5g-85k --freq 200 --package CABGA381
	@echo

$(BUILD_DIR)/%.json: $(PLL_FILES) $(TOP) $(BUILD_DIR)/%.v
	@echo Synthesizing design using yosys...
	@yosys -ql $(BUILD_DIR)/$*.log -p 'synth_ecp5 -top top -json $@' $^
	@echo

$(BUILD_DIR)/%.v: $(SV_SOURCES) | $(BUILD_DIR)
	@echo Converting SystemVerilog to Verilog using sv2v...
	@sv2v -w $@ --top $* $(SV_SOURCES)

$(BUILD_DIR):
	@mkdir $(BUILD_DIR)

sim: $(SIM_VCD)

$(BUILD_DIR)/%.vcd: $(SV_SOURCES) | $(BUILD_DIR)
	verilator --binary $^ --top $*_tb -sv \
	--trace --no-trace-top -j 8 \
	--timescale-override 1ns/1ns \
	-Mdir $(BUILD_DIR)/verilator
	$(BUILD_DIR)/verilator/V$*_tb


clean:
	@echo Removing build files...
	@rm -rf $(BUILD_DIR)