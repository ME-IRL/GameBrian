TRELLIS?=/usr/share/trellis

TARGET = GameBrian
BOARD ?= ecp5-evn
IN_FREQ = 50
BUILD_DIR = build

## PLLs ##
PLLs = 60 65 70 75 80 100 150 200 250 275
PLL_FILES = $(foreach f,$(PLLs),$(BUILD_DIR)/PLL$f.v)
SV_SOURCES = $(wildcard src/*.sv)
TOP = src/board/$(BOARD).v
SOURCES = $(PLL_FILES) $(TOP) $(SV_SOURCES)

$(BUILD_DIR)/PLL%.v: | $(BUILD_DIR)
	@echo Generating $* MHz PLL...
	@ecppll -n PLL$* \
	--clkin_name   clk_in \
	-i $(IN_FREQ) \
	--clkout0_name clk_out \
	-o $* \
	--clkout1_name clk_spi \
	--clkout1 1 \
	-f $@ > /dev/null

.PHONY: prog flash $(TARGET) clean

# prog2: $(BUILD_DIR)/$(TARGET).svf
# 	# openocd -f ${TRELLIS}/misc/openocd/ecp5-evn.cfg -c "transport select jtag; init; svf $<; exit"
# 	# openocd -f ecp5-evn.cfg -c "transport select jtag; init; svf $<; exit"
# 	openFPGALoader -b ecp5_evn -f build/GameBrian.bit

#$(BUILD_DIR)/%.svf: $(BUILD_DIR)/%.bit ;

prog: $(BUILD_DIR)/$(TARGET).bit
	@# ecpprog -S $^
	@echo Programming to SRAM...
	@openFPGALoader -b ecp5_evn $^

flash: $(BUILD_DIR)/$(TARGET).bit
	@# ecpprog $^
	@echo Programming to flash...
	@openFPGALoader -b ecp5_evn -f $^

$(BUILD_DIR)/%.bit: $(BUILD_DIR)/%.cfg
	@#ecppack --svf-rowsize 100000 --svf $(BUILD_DIR)/$*.svf $^ $@
	@echo Packing to bitstream...
	@ecppack $^ $@ --spimode fast-read

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

clean:
	@echo Removing build files...
	@rm -rf $(BUILD_DIR)