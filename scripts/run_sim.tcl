set root [file normalize [file join [file dirname [info script]] ..]]
set build [file join $root build]
file mkdir $build

set srcs [concat \
    [glob -directory [file join $root rtl] *.v] \
    [glob -directory [file join $root tb] *.v]]

puts "Compiling [llength $srcs] files..."
exec iverilog -g2012 -Wall -o [file join $build uart_sim] {*}$srcs

cd $build
set log [exec vvp uart_sim]
puts $log

set fh [open [file join $build sim.log] w]
puts $fh $log
close $fh

if {[string match "*RESULT*: PASS*" $log]} {
    puts "Simulation passed"
    exit 0
} else {
    puts "Simulation failed"
    exit 1
}
