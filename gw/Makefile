.PHONY: prog build time clean sim

TRELLIS?=/home/brian/Workspace/lunar/tools/oss-cad-suite/latest/share/trellis

BUILD_DIR = build
TARGET = top

PLLs = 60 65 70 75 80 100 150 200 250 275
PLL_FILES = $(foreach f,$(PLLs),$(BUILD_DIR)/PLL$f.v)
SOURCE_V = $(wildcard *.v)
.SECONDARY: $(PLL_FILES)

prog: $(BUILD_DIR)/$(TARGET).svf
	openocd -f ${TRELLIS}/misc/openocd/ecp5-evn.cfg -c "transport select jtag; init; svf $<; exit"

$(BUILD_DIR)/%.svf: $(BUILD_DIR)/%.bit ;

$(BUILD_DIR)/%.bit: $(BUILD_DIR)/%.config
	ecppack --svf-rowsize 100000 --svf $(BUILD_DIR)/$*.svf $^ $@

$(BUILD_DIR)/%.config: %.lpf $(BUILD_DIR)/%.json
	@echo Placing and routing using nextpnr...
	@nextpnr-ecp5 --json $(word 2, $^) --lpf $< --textcfg $@ --um5g-85k --freq 200 --package CABGA381
	@echo

$(BUILD_DIR)/PLL%.v:
	@mkdir -p build
	@echo Generating $* MHz PLL...
	@ecppll -n PLL$* -i 50 --clkin_name clk_in --clkout0_name clk_out --clkout1_name clk_spi --clkout1 1 -o $* -f $@ > /dev/null

$(BUILD_DIR)/%.json: $(SOURCE_V) $(PLL_FILES)
	@mkdir -p $(BUILD_DIR)
	@echo Synthesizing design using yosys...
	@yosys -ql $(BUILD_DIR)/$*.log -p 'synth_ecp5 -top $* -json $@' $^
	@echo

sim: $(TARGET).vcd

$(TARGET).vcd: $(BUILD_DIR)/$(TARGET).vvp
	vvp $^

$(BUILD_DIR)/$(TARGET).vvp: $(SOURCE_V) simulation.vv
	iverilog -o $@ $^

clean:
	@echo Removing build files...
	@rm -rf $(BUILD_DIR)

# $(BUILD_DIR)/ice_logic.json: hw/gen/LogicTop.v $(PLL_FILES)
# 	@mkdir -p $(BUILD_DIR)
# 	@echo Synthesizing design using yosys...
# 	@yosys -ql $(BUILD_DIR)/ice_logic.log -p 'synth_ice40 -top LogicTop -json $@' $^
# 	@echo

