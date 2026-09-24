`timescale 1ns/1ps

module uart_top #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD     = 115_200
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    input  wire       rx,
    output wire       tx,
    output wire       tx_busy,
    output wire       tx_done,
    output wire [7:0] rx_data,
    output wire       rx_valid,
    output wire       frame_err
);

    localparam CLKS_PER_BIT = CLK_FREQ / BAUD;

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_tx (
        .clk(clk), .rst(rst),
        .tx_start(tx_start), .tx_data(tx_data),
        .tx(tx), .tx_busy(tx_busy), .tx_done(tx_done)
    );

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_rx (
        .clk(clk), .rst(rst), .rx(rx),
        .rx_data(rx_data), .rx_valid(rx_valid), .frame_err(frame_err)
    );

endmodule
