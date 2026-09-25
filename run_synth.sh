#!/bin/sh
set -e
mkdir -p build
yosys -q -l build/synth.log synth/synth.ys
cat build/synth_stat.txt
iverilog -g2012 -DGLS -o build/uart_gls build/uart_netlist.v tb/tb_uart_loopback.v
cd build && vvp uart_gls | grep -E "Bytes|Framing|Errors|RESULT"
