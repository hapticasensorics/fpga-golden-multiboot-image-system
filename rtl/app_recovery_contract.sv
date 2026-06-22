`timescale 1ns / 1ps
`default_nettype none

module app_recovery_contract #(
    parameter [31:0] ABI_VERSION = 32'h0001_0000,
    parameter [31:0] BUILD_ID_LO = 32'h0000_0000,
    parameter [31:0] BUILD_ID_HI = 32'h0000_0000,
    parameter [31:0] WATCHDOG_UNLOCK_VALUE = 32'h1ee7_c0de
) (
    input  wire        clk,
    input  wire        rst,

    input  wire        bus_wr_en,
    input  wire        bus_rd_en,
    input  wire [11:0] bus_addr,
    input  wire [31:0] bus_wdata,
    output reg  [31:0] bus_rdata,

    input  wire        app_alive_tick,
    input  wire [31:0] app_status,
    input  wire [31:0] app_fault_code,

    output reg         return_to_golden_request,
    output reg         watchdog_expired
);

    localparam [31:0] APP_MAGIC      = 32'h4741_5050; // GAPP
    localparam [31:0] RETURN_MAGIC   = 32'h4752_4554; // GRET
    localparam [31:0] WATCHDOG_MAGIC = 32'h4757_4454; // GWDT
    localparam [31:0] TRIGGER_MAGIC  = 32'hb007_10ad;

    reg [31:0] heartbeat;
    reg [31:0] return_status;
    reg [31:0] return_reason;
    reg [31:0] watchdog_status;
    reg [31:0] watchdog_timeout_cycles;
    reg [31:0] watchdog_counter;
    reg        watchdog_locked;
    reg        watchdog_enabled;

    always @(posedge clk) begin
        if (rst) begin
            heartbeat <= 32'd0;
            return_status <= 32'd0;
            return_reason <= 32'd0;
            return_to_golden_request <= 1'b0;
            watchdog_status <= 32'd1;
            watchdog_timeout_cycles <= 32'd0;
            watchdog_counter <= 32'd0;
            watchdog_locked <= 1'b1;
            watchdog_enabled <= 1'b0;
            watchdog_expired <= 1'b0;
        end else begin
            return_to_golden_request <= 1'b0;

            if (app_alive_tick) begin
                heartbeat <= heartbeat + 32'd1;
            end

            if (watchdog_enabled && !watchdog_expired) begin
                watchdog_counter <= watchdog_counter + 32'd1;
                if (watchdog_timeout_cycles != 32'd0 &&
                    watchdog_counter >= watchdog_timeout_cycles) begin
                    watchdog_expired <= 1'b1;
                    watchdog_status <= 32'd4;
                    return_to_golden_request <= 1'b1;
                    return_reason <= 32'd4;
                end
            end

            if (bus_wr_en) begin
                case (bus_addr)
                    12'h10c: begin
                        if (bus_wdata == TRIGGER_MAGIC) begin
                            return_to_golden_request <= 1'b1;
                            return_status <= 32'd1;
                            return_reason <= 32'd1;
                        end
                    end
                    12'h208: begin
                        if (!watchdog_locked) begin
                            watchdog_timeout_cycles <= bus_wdata;
                        end
                    end
                    12'h20c: begin
                        if (watchdog_enabled) begin
                            watchdog_counter <= 32'd0;
                        end
                    end
                    12'h210: begin
                        if (bus_wdata == WATCHDOG_UNLOCK_VALUE) begin
                            watchdog_locked <= 1'b0;
                            watchdog_status <= 32'd2;
                        end
                    end
                    12'h214: begin
                        if (!watchdog_locked) begin
                            watchdog_enabled <= bus_wdata[0];
                            watchdog_counter <= 32'd0;
                            watchdog_expired <= 1'b0;
                            watchdog_status <= bus_wdata[0] ? 32'd3 : 32'd2;
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
                12'h000: bus_rdata = APP_MAGIC;
                12'h004: bus_rdata = ABI_VERSION;
                12'h008: bus_rdata = 32'h0000_0007;
                12'h00c: bus_rdata = app_status;
                12'h010: bus_rdata = BUILD_ID_LO;
                12'h014: bus_rdata = BUILD_ID_HI;
                12'h018: bus_rdata = heartbeat;
                12'h01c: bus_rdata = app_fault_code;
                12'h100: bus_rdata = RETURN_MAGIC;
                12'h104: bus_rdata = return_status;
                12'h108: bus_rdata = return_reason;
                12'h200: bus_rdata = WATCHDOG_MAGIC;
                12'h204: bus_rdata = watchdog_status;
                12'h208: bus_rdata = watchdog_timeout_cycles;
                12'h20c: bus_rdata = watchdog_counter;
                12'h214: bus_rdata = {30'd0, watchdog_enabled, watchdog_locked};
                default: bus_rdata = 32'd0;
            endcase
        end
    end

endmodule

`default_nettype wire

