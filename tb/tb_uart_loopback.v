`timescale 1ns/1ps

module tb_uart_loopback;

    localparam CLK_FREQ     = 50_000_000;
    localparam BAUD         = 115_200;
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD;
    localparam BIT_NS       = CLKS_PER_BIT * 20;

    reg        clk = 0;
    reg        rst = 1;
    reg        tx_start = 0;
    reg  [7:0] tx_data = 0;
    reg        force_line = 0;
    reg        line_val = 1;

    wire       tx, tx_busy, tx_done;
    wire [7:0] rx_data;
    wire       rx_valid, frame_err;
    wire       rx_line = force_line ? line_val : tx;

    integer errors = 0;
    integer sent   = 0;
    integer got    = 0;
    integer ferr   = 0;
    integer i;

    reg [7:0] expected [0:511];

    always #10 clk = ~clk;

    uart_top #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD)) dut (
        .clk(clk), .rst(rst),
        .tx_start(tx_start), .tx_data(tx_data),
        .rx(rx_line),
        .tx(tx), .tx_busy(tx_busy), .tx_done(tx_done),
        .rx_data(rx_data), .rx_valid(rx_valid), .frame_err(frame_err)
    );

    always @(posedge clk) begin
        if (rx_valid) begin
            if (rx_data !== expected[got]) begin
                errors = errors + 1;
                $display("FAIL byte %0d: got %h expected %h", got, rx_data, expected[got]);
            end
            got = got + 1;
        end
        if (frame_err)
            ferr = ferr + 1;
    end

    task send_byte(input [7:0] d);
        begin
            @(posedge clk);
            while (tx_busy) @(posedge clk);
            expected[sent] = d;
            sent = sent + 1;
            tx_data  <= d;
            tx_start <= 1'b1;
            @(posedge clk);
            tx_start <= 1'b0;
            @(posedge tx_done);
        end
    endtask

    task send_bad_frame(input [7:0] d);
        integer k;
        begin
            force_line = 1;
            line_val = 0; #(BIT_NS);
            for (k = 0; k < 8; k = k + 1) begin
                line_val = d[k]; #(BIT_NS);
            end
            line_val = 0; #(BIT_NS);
            line_val = 1; #(BIT_NS * 2);
            force_line = 0;
        end
    endtask

    initial begin
        $dumpfile("uart.vcd");
        $dumpvars(0, tb_uart_loopback);

        repeat (5) @(posedge clk);
        rst = 0;
        repeat (5) @(posedge clk);

        send_byte(8'h00);
        send_byte(8'hFF);
        send_byte(8'h55);
        send_byte(8'hAA);
        send_byte(8'h01);
        send_byte(8'h80);

        for (i = 0; i < 50; i = i + 1)
            send_byte($random);

        repeat (CLKS_PER_BIT * 2) @(posedge clk);

        send_bad_frame(8'h3C);
        repeat (CLKS_PER_BIT * 2) @(posedge clk);

        if (got != sent) begin
            errors = errors + 1;
            $display("FAIL: sent %0d bytes, received %0d", sent, got);
        end
        if (ferr != 1) begin
            errors = errors + 1;
            $display("FAIL: expected 1 framing error, saw %0d", ferr);
        end

        $display("--------------------------------");
        $display("Bytes sent      : %0d", sent);
        $display("Bytes received  : %0d", got);
        $display("Framing errors  : %0d (1 expected)", ferr);
        $display("Errors          : %0d", errors);
        if (errors == 0) $display("RESULT          : PASS");
        else             $display("RESULT          : FAIL");
        $finish;
    end

endmodule
