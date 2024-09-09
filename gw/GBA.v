module GBA (
    input  wire          clk,
    input  wire          rst,

    input  wire          GBA_CLK,
    input  wire          GBA_nWR,
    input  wire          GBA_nRD,
    input  wire          GBA_nCS,
    input  wire          GBA_VDD,
    inout  wire [15:0]   GBA_AD,
    inout  wire [7:0]    GBA_A,
    input  wire          GBA_nCS2,
    output wire          GBA_nREQ,

    output wire [15:0]   addr,
    input  wire [7:0]    miso,
    output wire [7:0]    mosi,
    output wire          write
);
    assign GBA_nREQ = GBA_VDD;

    // ROM
    reg [15:0] rom [0:511];
    initial begin
        $readmemh("rom/fire_16.hex", rom);
    end

    // Synchronize
    reg [2:0] sync_nWR;
    reg [2:0] sync_nRD;
    reg [2:0] sync_nCS;
    reg [2:0] sync_nCS2;

    wire sWR = sync_nWR[0];
    wire sRD = sync_nRD[0];
    wire sCS = sync_nCS[0];
    wire sCS2 = sync_nCS2[0];
    wire ssWR = sync_nWR[1];
    wire ssRD = sync_nRD[1];
    wire ssCS = sync_nCS[1];
    wire ssCS2 = sync_nCS2[1];

    initial begin
        sync_nWR <= 0;
        sync_nRD <= 0;
        sync_nCS <= 0;
        sync_nCS2 <= 0;
    end

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            sync_nWR <= 0;
            sync_nRD <= 0;
            sync_nCS <= 0;
            sync_nCS2 <= 0;
        end else begin
            sync_nWR <= {sync_nWR[1:0], GBA_nWR};
            sync_nRD <= {sync_nRD[1:0], GBA_nRD};
            sync_nCS <= {sync_nCS[1:0], GBA_nCS};
            sync_nCS2 <= {sync_nCS2[1:0], GBA_nCS2};
        end
    end

    // // ROM Logic
    // reg [15:0] latched_rom_addr;
    // wire [23:0] rom_addr = {GBA_A, latched_rom_addr};
    // wire [15:0] rom_data = rom[rom_addr];
    // assign GBA_AD = (!ssRD && !ssCS && GBA_VDD) ? rom_data : 16'hz;

    // wire fCS = ssCS && !sCS;
    // wire rRD = !ssRD && sRD;
    // always @(posedge clk) begin
    //     if(fCS)
    //         latched_rom_addr <= GBA_AD;
    //     if(rRD)
    //         latched_rom_addr <= latched_rom_addr + 1;

    // end

    // // RAM Logic
    // assign GBA_A = (!ssRD && !ssCS2 && GBA_VDD) ? miso: 8'hz;
    // // assign GBA_A = 8'hz;
    // assign write = !ssWR && !ssCS2 && GBA_VDD;
    // // assign read = !ssRD && !ssCS2 && GBA_VDD;
    // assign addr = GBA_AD;
    // assign mosi = GBA_A;

    // ROM Logic
    reg [15:0] latched_rom_addr;
    wire [23:0] rom_addr = {GBA_A, latched_rom_addr};
    wire [15:0] rom_data = rom[rom_addr];
    assign GBA_AD = (!ssRD && !ssCS && GBA_VDD) ? rom_data : 16'hz;

    wire fCS = ssCS && !sCS;
    wire rRD = !ssRD && sRD;
    always @(posedge clk) begin
        if(fCS)
            latched_rom_addr <= GBA_AD;
        if(rRD)
            latched_rom_addr <= latched_rom_addr + 1;
    end

    // RAM Logic
    assign GBA_A = (!ssRD && !ssCS2 && GBA_VDD) ? miso: 8'hz;
    assign write = !ssWR && !ssCS2 && GBA_VDD;
    assign addr = GBA_AD;
    assign mosi = GBA_A;
endmodule