`timescale 1ns / 1ps
`default_nettype none

module health_telemetry_regs #(
    parameter [31:0] ABI_VERSION = 32'h0001_0000
) (
    input  wire        clk,
    input  wire        rst,

    input  wire        bus_rd_en,
    input  wire [11:0] bus_addr,
    output reg  [31:0] bus_rdata,

    input  wire        sample_valid,
    input  wire [31:0] temperature_mdeg_c,
    input  wire [31:0] vccint_mv,
    input  wire [31:0] vccaux_mv,
    input  wire [31:0] alarm_flags,
    input  wire [31:0] transport_status
);

    localparam [31:0] HEALTH_MAGIC = 32'h4748_4c54; // GHLT

    reg [31:0] sample_count;
    reg [31:0] max_temperature_mdeg_c;
    reg [31:0] min_temperature_mdeg_c;
    reg [31:0] sticky_alarm_flags;

    always @(posedge clk) begin
        if (rst) begin
            sample_count <= 32'd0;
            max_temperature_mdeg_c <= 32'd0;
            min_temperature_mdeg_c <= 32'hffff_ffff;
            sticky_alarm_flags <= 32'd0;
        end else if (sample_valid) begin
            sample_count <= sample_count + 32'd1;
            if (temperature_mdeg_c > max_temperature_mdeg_c) begin
                max_temperature_mdeg_c <= temperature_mdeg_c;
            end
            if (temperature_mdeg_c < min_temperature_mdeg_c) begin
                min_temperature_mdeg_c <= temperature_mdeg_c;
            end
            sticky_alarm_flags <= sticky_alarm_flags | alarm_flags;
        end
    end

    always @(*) begin
        bus_rdata = 32'd0;
        if (bus_rd_en) begin
            case (bus_addr)
                12'h000: bus_rdata = HEALTH_MAGIC;
                12'h004: bus_rdata = ABI_VERSION;
                12'h008: bus_rdata = sample_count;
                12'h00c: bus_rdata = temperature_mdeg_c;
                12'h010: bus_rdata = max_temperature_mdeg_c;
                12'h014: bus_rdata = min_temperature_mdeg_c;
                12'h018: bus_rdata = vccint_mv;
                12'h01c: bus_rdata = vccaux_mv;
                12'h020: bus_rdata = alarm_flags;
                12'h024: bus_rdata = sticky_alarm_flags;
                12'h028: bus_rdata = transport_status;
                default: bus_rdata = 32'd0;
            endcase
        end
    end

endmodule

`default_nettype wire

