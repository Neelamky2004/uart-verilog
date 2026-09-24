`timescale 1ns/1ps

module uart_tx #(
    parameter CLKS_PER_BIT = 434
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    output reg        tx,
    output reg        tx_busy,
    output reg        tx_done
);

    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0]  state;
    reg [15:0] clk_cnt;
    reg [2:0]  bit_idx;
    reg [7:0]  shreg;

    always @(posedge clk) begin
        if (rst) begin
            state   <= IDLE;
            clk_cnt <= 0;
            bit_idx <= 0;
            shreg   <= 0;
            tx      <= 1'b1;
            tx_busy <= 1'b0;
            tx_done <= 1'b0;
        end else begin
            tx_done <= 1'b0;
            case (state)
                IDLE: begin
                    tx      <= 1'b1;
                    clk_cnt <= 0;
                    bit_idx <= 0;
                    if (tx_start) begin
                        shreg   <= tx_data;
                        tx_busy <= 1'b1;
                        state   <= START;
                    end
                end
                START: begin
                    tx <= 1'b0;
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        state   <= DATA;
                    end else
                        clk_cnt <= clk_cnt + 1;
                end
                DATA: begin
                    tx <= shreg[bit_idx];
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        if (bit_idx == 3'd7) begin
                            bit_idx <= 0;
                            state   <= STOP;
                        end else
                            bit_idx <= bit_idx + 1;
                    end else
                        clk_cnt <= clk_cnt + 1;
                end
                STOP: begin
                    tx <= 1'b1;
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        tx_busy <= 1'b0;
                        tx_done <= 1'b1;
                        state   <= IDLE;
                    end else
                        clk_cnt <= clk_cnt + 1;
                end
            endcase
        end
    end

endmodule
