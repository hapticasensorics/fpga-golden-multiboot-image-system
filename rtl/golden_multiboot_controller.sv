`timescale 1ns / 1ps
`default_nettype none

module golden_multiboot_controller #(
    parameter [31:0] ABI_VERSION = 32'h0001_0000,
    parameter [31:0] BUILD_ID_LO = 32'h0000_0000,
    parameter [31:0] BUILD_ID_HI = 32'h0000_0000,
    parameter [31:0] GOLDEN_LIMIT_EXCLUSIVE = 32'h0040_0000,
    parameter [31:0] UPDATE_REGION_END = 32'h0100_0000,
    parameter [31:0] PAYLOAD_ALIGNMENT_MASK = 32'h0000_00ff,
    parameter [31:0] DEFAULT_SLOT_A_PAYLOAD = 32'h0068_0100,
    parameter [31:0] DEFAULT_SLOT_B_PAYLOAD = 32'h00a8_0100
) (
    input  wire        clk,
    input  wire        rst,

    input  wire        bus_wr_en,
    input  wire        bus_rd_en,
    input  wire [11:0] bus_addr,
    input  wire [31:0] bus_wdata,
    output reg  [31:0] bus_rdata,

    input  wire        slot_a_verified,
    input  wire        slot_b_verified,
    input  wire [31:0] boot_status_word,
    input  wire [31:0] config_status_word,
    input  wire [31:0] warmboot_start_word,
    input  wire [31:0] health_temperature_mdeg_c,
    input  wire        thermal_policy_ok,

    output reg         warmboot_request,
    output reg  [31:0] warmboot_address,
    output reg  [31:0] boot_reason,
    output reg  [31:0] event_code
);

    localparam [31:0] GOLDEN_MAGIC     = 32'h474d_4230; // GMB0
    localparam [31:0] IMAGE_KIND_GOLD  = 32'h0000_0001;
    localparam [31:0] CAPABILITIES     = 32'h0000_007f;
    localparam [31:0] TRIGGER_MAGIC    = 32'hb007_10ad;

    localparam [31:0] REJECT_NONE      = 32'd0;
    localparam [31:0] REJECT_NOT_ARMED = 32'd1;
    localparam [31:0] REJECT_BUSY      = 32'd2;
    localparam [31:0] REJECT_LOW_ADDR  = 32'd3;
    localparam [31:0] REJECT_HIGH_ADDR = 32'd4;
    localparam [31:0] REJECT_ALIGN     = 32'd5;
    localparam [31:0] REJECT_MAGIC     = 32'd6;
    localparam [31:0] REJECT_SLOT      = 32'd7;
    localparam [31:0] REJECT_THERMAL   = 32'd8;

    localparam [31:0] STATUS_IDLE      = 32'd0;
    localparam [31:0] STATUS_ACCEPTED  = 32'd1;
    localparam [31:0] STATUS_REJECTED  = 32'd2;

    reg [31:0] requested_boot_addr;
    reg [31:0] boot_flags;
    reg [31:0] status_reg;
    reg [31:0] reject_code;
    reg [31:0] clear_count;
    reg [31:0] trigger_count;

    wire selected_slot_a = (boot_flags[1:0] == 2'd1);
    wire selected_slot_b = (boot_flags[1:0] == 2'd2);
    wire selected_slot_verified =
        (selected_slot_a && slot_a_verified) ||
        (selected_slot_b && slot_b_verified);

    wire addr_too_low  = requested_boot_addr < GOLDEN_LIMIT_EXCLUSIVE;
    wire addr_too_high = requested_boot_addr >= UPDATE_REGION_END;
    wire addr_unaligned = (requested_boot_addr & PAYLOAD_ALIGNMENT_MASK) != 32'd0;

    always @(posedge clk) begin
        if (rst) begin
            requested_boot_addr <= DEFAULT_SLOT_A_PAYLOAD;
            boot_flags <= 32'd1;
            status_reg <= STATUS_IDLE;
            reject_code <= REJECT_NONE;
            clear_count <= 32'd0;
            trigger_count <= 32'd0;
            warmboot_request <= 1'b0;
            warmboot_address <= 32'd0;
            boot_reason <= 32'd1;
            event_code <= 32'd1;
        end else begin
            warmboot_request <= 1'b0;

            if (bus_wr_en) begin
                case (bus_addr)
                    12'h120: requested_boot_addr <= bus_wdata;
                    12'h124: boot_flags <= bus_wdata;
                    12'h130: begin
                        if (bus_wdata[0]) begin
                            status_reg <= STATUS_IDLE;
                            reject_code <= REJECT_NONE;
                            clear_count <= clear_count + 32'd1;
                        end
                    end
                    12'h134: begin
                        trigger_count <= trigger_count + 32'd1;
                        if (bus_wdata != TRIGGER_MAGIC) begin
                            status_reg <= STATUS_REJECTED;
                            reject_code <= REJECT_MAGIC;
                            event_code <= 32'd2;
                        end else if (!thermal_policy_ok) begin
                            status_reg <= STATUS_REJECTED;
                            reject_code <= REJECT_THERMAL;
                            event_code <= 32'd2;
                        end else if (addr_too_low) begin
                            status_reg <= STATUS_REJECTED;
                            reject_code <= REJECT_LOW_ADDR;
                            event_code <= 32'd2;
                        end else if (addr_too_high) begin
                            status_reg <= STATUS_REJECTED;
                            reject_code <= REJECT_HIGH_ADDR;
                            event_code <= 32'd2;
                        end else if (addr_unaligned) begin
                            status_reg <= STATUS_REJECTED;
                            reject_code <= REJECT_ALIGN;
                            event_code <= 32'd2;
                        end else if (!selected_slot_verified) begin
                            status_reg <= STATUS_REJECTED;
                            reject_code <= REJECT_SLOT;
                            event_code <= 32'd2;
                        end else begin
                            warmboot_request <= 1'b1;
                            warmboot_address <= requested_boot_addr;
                            status_reg <= STATUS_ACCEPTED;
                            reject_code <= REJECT_NONE;
                            boot_reason <= 32'd2;
                            event_code <= 32'd3;
                        end
                    end
                    default: begin
                    end
                endcase
            end
        end
    end

    always @(*) begin
        bus_rdata = 32'd0;
        if (bus_rd_en) begin
            case (bus_addr)
                12'h000: bus_rdata = GOLDEN_MAGIC;
                12'h004: bus_rdata = ABI_VERSION;
                12'h008: bus_rdata = IMAGE_KIND_GOLD;
                12'h00c: bus_rdata = CAPABILITIES;
                12'h010: bus_rdata = BUILD_ID_LO;
                12'h014: bus_rdata = BUILD_ID_HI;
                12'h020: bus_rdata = boot_reason;
                12'h024: bus_rdata = reject_code;
                12'h028: bus_rdata = event_code;
                12'h080: bus_rdata = DEFAULT_SLOT_A_PAYLOAD - 32'h100;
                12'h084: bus_rdata = DEFAULT_SLOT_A_PAYLOAD;
                12'h08c: bus_rdata = {31'd0, slot_a_verified};
                12'h090: bus_rdata = DEFAULT_SLOT_B_PAYLOAD - 32'h100;
                12'h094: bus_rdata = DEFAULT_SLOT_B_PAYLOAD;
                12'h09c: bus_rdata = {31'd0, slot_b_verified};
                12'h120: bus_rdata = requested_boot_addr;
                12'h124: bus_rdata = boot_flags;
                12'h128: bus_rdata = status_reg;
                12'h12c: bus_rdata = reject_code;
                12'h140: bus_rdata = boot_status_word;
                12'h144: bus_rdata = config_status_word;
                12'h148: bus_rdata = warmboot_start_word;
                12'h14c: bus_rdata = trigger_count;
                12'h150: bus_rdata = clear_count;
                12'h180: bus_rdata = health_temperature_mdeg_c;
                default: bus_rdata = 32'd0;
            endcase
        end
    end

endmodule

`default_nettype wire

