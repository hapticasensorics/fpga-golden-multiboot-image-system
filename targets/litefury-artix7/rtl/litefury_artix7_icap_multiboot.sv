`timescale 1ns / 1ps
`default_nettype none

module litefury_artix7_icap_multiboot #(
    parameter integer SIMULATION = 0
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        request,
    input  wire [31:0] flash_address,
    output reg         busy,
    output reg         accepted,
    output reg         done,
    output reg  [31:0] word_count
);

    localparam [3:0] ST_IDLE  = 4'd0;
    localparam [3:0] ST_WORD0 = 4'd1;
    localparam [3:0] ST_WORD1 = 4'd2;
    localparam [3:0] ST_WORD2 = 4'd3;
    localparam [3:0] ST_WORD3 = 4'd4;
    localparam [3:0] ST_WORD4 = 4'd5;
    localparam [3:0] ST_WORD5 = 4'd6;
    localparam [3:0] ST_WORD6 = 4'd7;
    localparam [3:0] ST_DONE  = 4'd8;

    reg [3:0] state;
    reg [31:0] icap_i;
    reg        icap_csib;

    function [31:0] bit_reverse_word;
        input [31:0] value;
        integer i;
        begin
            for (i = 0; i < 32; i = i + 1) begin
                bit_reverse_word[i] = value[31 - i];
            end
        end
    endfunction

    function [31:0] icap_word;
        input [31:0] value;
        begin
            icap_word = bit_reverse_word(value);
        end
    endfunction

    wire [31:0] wbstar_payload = flash_address;

    always @(posedge clk) begin
        if (rst) begin
            state <= ST_IDLE;
            busy <= 1'b0;
            accepted <= 1'b0;
            done <= 1'b0;
            word_count <= 32'd0;
            icap_i <= 32'hffff_ffff;
            icap_csib <= 1'b1;
        end else begin
            accepted <= 1'b0;
            done <= 1'b0;
            case (state)
                ST_IDLE: begin
                    busy <= 1'b0;
                    icap_csib <= 1'b1;
                    if (request) begin
                        busy <= 1'b1;
                        accepted <= 1'b1;
                        word_count <= 32'd0;
                        state <= ST_WORD0;
                    end
                end
                ST_WORD0: begin
                    icap_csib <= 1'b0;
                    icap_i <= icap_word(32'hffff_ffff);
                    word_count <= word_count + 32'd1;
                    state <= ST_WORD1;
                end
                ST_WORD1: begin
                    icap_i <= icap_word(32'haa99_5566);
                    word_count <= word_count + 32'd1;
                    state <= ST_WORD2;
                end
                ST_WORD2: begin
                    icap_i <= icap_word(32'h2000_0000);
                    word_count <= word_count + 32'd1;
                    state <= ST_WORD3;
                end
                ST_WORD3: begin
                    icap_i <= icap_word(32'h3002_0001);
                    word_count <= word_count + 32'd1;
                    state <= ST_WORD4;
                end
                ST_WORD4: begin
                    icap_i <= icap_word(wbstar_payload);
                    word_count <= word_count + 32'd1;
                    state <= ST_WORD5;
                end
                ST_WORD5: begin
                    icap_i <= icap_word(32'h3000_8001);
                    word_count <= word_count + 32'd1;
                    state <= ST_WORD6;
                end
                ST_WORD6: begin
                    icap_i <= icap_word(32'h0000_000f);
                    word_count <= word_count + 32'd1;
                    state <= ST_DONE;
                end
                ST_DONE: begin
                    icap_csib <= 1'b1;
                    busy <= 1'b0;
                    done <= 1'b1;
                    state <= ST_IDLE;
                end
                default: state <= ST_IDLE;
            endcase
        end
    end

    generate
        if (SIMULATION == 0) begin : g_icape2
            wire [31:0] icap_o_unused;
            ICAPE2 #(
                .DEVICE_ID(32'h0363_1093),
                .ICAP_WIDTH("X32"),
                .SIM_CFG_FILE_NAME("NONE")
            ) icape2_inst (
                .O(icap_o_unused),
                .CLK(clk),
                .CSIB(icap_csib),
                .I(icap_i),
                .RDWRB(1'b0)
            );
        end
    endgenerate

endmodule

`default_nettype wire

