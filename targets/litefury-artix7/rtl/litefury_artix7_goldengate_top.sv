`timescale 1ns / 1ps
`default_nettype none

module litefury_artix7_goldengate_top #(
    parameter integer SIMULATION = 0,
    parameter [31:0] ABI_VERSION = 32'h0001_0000,
    parameter [31:0] BUILD_ID_LO = 32'h0000_0000,
    parameter [31:0] BUILD_ID_HI = 32'h0000_0000,
    parameter [15:0] GOLDEN_BAR_BASE = 16'h7000,
    parameter [15:0] HEALTH_BAR_BASE = 16'h63c0,
    parameter [31:0] GOLDEN_LIMIT_EXCLUSIVE = 32'h0040_0000,
    parameter [31:0] UPDATE_REGION_END = 32'h0100_0000,
    parameter [31:0] DEFAULT_SLOT_A_PAYLOAD = 32'h0068_0100,
    parameter [31:0] DEFAULT_SLOT_B_PAYLOAD = 32'h00a8_0100,
    parameter [31:0] THERMAL_LIMIT_MDEG_C = 32'd95000,
    parameter [31:0] THERMAL_FATAL_ALARM_MASK = 32'h0000_0001
) (
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,

    input  wire [15:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,

    input  wire [15:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,

    input  wire        slot_a_verified,
    input  wire        slot_b_verified,
    input  wire [31:0] boot_status_word,
    input  wire [31:0] config_status_word,

    input  wire        health_sample_valid,
    input  wire [31:0] temperature_mdeg_c,
    input  wire [31:0] vccint_mv,
    input  wire [31:0] vccaux_mv,
    input  wire [31:0] alarm_flags,
    input  wire [31:0] transport_status,

    output wire        warmboot_request_pulse,
    output wire [31:0] warmboot_address,
    output wire        icap_busy,
    output wire        icap_accepted,
    output wire        icap_done,
    output wire        thermal_policy_ok
);

    localparam [1:0] AXI_RESP_OKAY   = 2'b00;
    localparam [1:0] AXI_RESP_DECERR = 2'b11;

    wire rst = ~s_axi_aresetn;

    reg        aw_latched;
    reg [15:0] awaddr_reg;
    reg        w_latched;
    reg [31:0] wdata_reg;
    reg [3:0]  wstrb_reg;

    wire write_fire = aw_latched && w_latched && !s_axi_bvalid;

    assign s_axi_awready = !aw_latched && !s_axi_bvalid;
    assign s_axi_wready  = !w_latched && !s_axi_bvalid;
    assign s_axi_arready = !s_axi_rvalid && !write_fire;

    wire aw_accept = s_axi_awvalid && s_axi_awready;
    wire w_accept = s_axi_wvalid && s_axi_wready;
    wire ar_accept = s_axi_arvalid && s_axi_arready;

    wire wr_sel_golden =
        (awaddr_reg >= GOLDEN_BAR_BASE) &&
        (awaddr_reg < (GOLDEN_BAR_BASE + 16'h1000));
    wire [15:0] wr_golden_rel = awaddr_reg - GOLDEN_BAR_BASE;

    wire ar_sel_golden =
        (s_axi_araddr >= GOLDEN_BAR_BASE) &&
        (s_axi_araddr < (GOLDEN_BAR_BASE + 16'h1000));
    wire ar_sel_health =
        (s_axi_araddr >= HEALTH_BAR_BASE) &&
        (s_axi_araddr < (HEALTH_BAR_BASE + 16'h0040));
    wire [15:0] ar_golden_rel = s_axi_araddr - GOLDEN_BAR_BASE;
    wire [15:0] ar_health_rel = s_axi_araddr - HEALTH_BAR_BASE;

    wire golden_wr_en = write_fire && wr_sel_golden && (wstrb_reg != 4'd0);
    wire golden_rd_en = ar_accept && ar_sel_golden;
    wire health_rd_en = ar_accept && ar_sel_health;

    wire [31:0] golden_rdata;
    wire [31:0] health_rdata;
    wire        golden_warmboot_request;
    wire [31:0] golden_warmboot_address;
    wire [31:0] golden_boot_reason;
    wire [31:0] golden_event_code;
    wire [31:0] icap_word_count;

    assign thermal_policy_ok =
        (temperature_mdeg_c <= THERMAL_LIMIT_MDEG_C) &&
        ((alarm_flags & THERMAL_FATAL_ALARM_MASK) == 32'd0);

    golden_multiboot_controller #(
        .ABI_VERSION(ABI_VERSION),
        .BUILD_ID_LO(BUILD_ID_LO),
        .BUILD_ID_HI(BUILD_ID_HI),
        .GOLDEN_LIMIT_EXCLUSIVE(GOLDEN_LIMIT_EXCLUSIVE),
        .UPDATE_REGION_END(UPDATE_REGION_END),
        .DEFAULT_SLOT_A_PAYLOAD(DEFAULT_SLOT_A_PAYLOAD),
        .DEFAULT_SLOT_B_PAYLOAD(DEFAULT_SLOT_B_PAYLOAD)
    ) golden_regs (
        .clk(s_axi_aclk),
        .rst(rst),
        .bus_wr_en(golden_wr_en),
        .bus_rd_en(golden_rd_en),
        .bus_addr(golden_wr_en ? wr_golden_rel[11:0] : ar_golden_rel[11:0]),
        .bus_wdata(wdata_reg),
        .bus_rdata(golden_rdata),
        .slot_a_verified(slot_a_verified),
        .slot_b_verified(slot_b_verified),
        .boot_status_word(boot_status_word),
        .config_status_word(config_status_word),
        .warmboot_start_word(icap_word_count),
        .health_temperature_mdeg_c(temperature_mdeg_c),
        .thermal_policy_ok(thermal_policy_ok),
        .warmboot_request(golden_warmboot_request),
        .warmboot_address(golden_warmboot_address),
        .boot_reason(golden_boot_reason),
        .event_code(golden_event_code)
    );

    health_telemetry_regs #(
        .ABI_VERSION(ABI_VERSION)
    ) health_regs (
        .clk(s_axi_aclk),
        .rst(rst),
        .bus_rd_en(health_rd_en),
        .bus_addr(ar_health_rel[11:0]),
        .bus_rdata(health_rdata),
        .sample_valid(health_sample_valid),
        .temperature_mdeg_c(temperature_mdeg_c),
        .vccint_mv(vccint_mv),
        .vccaux_mv(vccaux_mv),
        .alarm_flags(alarm_flags),
        .transport_status(transport_status)
    );

    litefury_artix7_icap_multiboot #(
        .SIMULATION(SIMULATION)
    ) icap_multiboot (
        .clk(s_axi_aclk),
        .rst(rst),
        .request(golden_warmboot_request),
        .flash_address(golden_warmboot_address),
        .busy(icap_busy),
        .accepted(icap_accepted),
        .done(icap_done),
        .word_count(icap_word_count)
    );

    assign warmboot_request_pulse = golden_warmboot_request;
    assign warmboot_address = golden_warmboot_address;

    always @(posedge s_axi_aclk) begin
        if (rst) begin
            aw_latched <= 1'b0;
            awaddr_reg <= 16'd0;
            w_latched <= 1'b0;
            wdata_reg <= 32'd0;
            wstrb_reg <= 4'd0;
            s_axi_bresp <= AXI_RESP_OKAY;
            s_axi_bvalid <= 1'b0;
        end else begin
            if (aw_accept) begin
                aw_latched <= 1'b1;
                awaddr_reg <= s_axi_awaddr;
            end

            if (w_accept) begin
                w_latched <= 1'b1;
                wdata_reg <= s_axi_wdata;
                wstrb_reg <= s_axi_wstrb;
            end

            if (write_fire) begin
                aw_latched <= 1'b0;
                w_latched <= 1'b0;
                s_axi_bvalid <= 1'b1;
                s_axi_bresp <= wr_sel_golden ? AXI_RESP_OKAY : AXI_RESP_DECERR;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    always @(posedge s_axi_aclk) begin
        if (rst) begin
            s_axi_rdata <= 32'd0;
            s_axi_rresp <= AXI_RESP_OKAY;
            s_axi_rvalid <= 1'b0;
        end else begin
            if (ar_accept) begin
                s_axi_rvalid <= 1'b1;
                if (ar_sel_golden) begin
                    s_axi_rdata <= golden_rdata;
                    s_axi_rresp <= AXI_RESP_OKAY;
                end else if (ar_sel_health) begin
                    s_axi_rdata <= health_rdata;
                    s_axi_rresp <= AXI_RESP_OKAY;
                end else begin
                    s_axi_rdata <= 32'd0;
                    s_axi_rresp <= AXI_RESP_DECERR;
                end
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule

`default_nettype wire
