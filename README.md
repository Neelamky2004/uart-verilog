# UART Transmitter and Receiver in Verilog

A UART (8N1) transmitter and receiver written in Verilog as finite state machines, tested with a loopback testbench and run through a Tcl simulation script.

Default setting: 50 MHz clock, 115200 baud (434 clocks per bit). Both are parameters in `uart_top`.

## Design

**uart_tx** — FSM with IDLE, START, DATA, STOP states. Loads a byte on `tx_start`, sends start bit, 8 data bits (LSB first) and stop bit. Gives `tx_busy` and a one-cycle `tx_done`.

**uart_rx** — FSM with the same four states.
- 2-flop synchronizer on the `rx` input
- Checks the start bit again at its middle to ignore glitches
- Samples each data bit at the middle of the bit period
- Raises `rx_valid` for a good frame and `frame_err` if the stop bit is 0

**uart_top** — puts TX and RX together and works out clocks-per-bit from `CLK_FREQ` and `BAUD`.

## Verification

`tb/tb_uart_loopback.v` connects TX output to RX input.

- Corner bytes: 0x00, 0xFF, 0x55, 0xAA, 0x01, 0x80
- 50 random bytes
- Every received byte is checked against a queue of sent bytes
- One frame with a bad stop bit is driven directly on the line to check `frame_err`
- Dumps a VCD waveform

```
Bytes sent      : 56
Bytes received  : 56
Framing errors  : 1 (1 expected)
Errors          : 0
RESULT          : PASS
```

## Run

```
sh run.sh
gtkwave build/uart.vcd
```

`scripts/run_sim.tcl` compiles all RTL and testbench files with Icarus Verilog, runs the simulation, saves `build/sim.log` and exits with a pass/fail code.

Needs Icarus Verilog and `tclsh`. GTKWave is optional.

## Structure

```
rtl/uart_tx.v              transmitter FSM
rtl/uart_rx.v              receiver FSM
rtl/uart_top.v             top module
tb/tb_uart_loopback.v      loopback testbench
scripts/run_sim.tcl        Tcl build + run script
run.sh                     wrapper
```
