#!/usr/bin/perl
use strict;
use warnings;

my $sim_log  = shift // "build/sim.log";
my $stat_log = shift // "build/synth_stat.txt";

my %sim;
open(my $fh, "<", $sim_log) or die "Cannot open $sim_log: $!\n";
while (my $line = <$fh>) {
    if ($line =~ /^(Bytes sent|Bytes received|Framing errors|Errors|RESULT)\s*:\s*(\S+)/) {
        $sim{$1} = $2;
    }
}
close($fh);

my ($cells, $ffs, $gates) = (0, 0, 0);
if (open(my $sh, "<", $stat_log)) {
    while (my $line = <$sh>) {
        if ($line =~ /Number of cells:\s+(\d+)/) {
            $cells = $1;
        } elsif ($line =~ /^\s+\$_(\S+)_\s+(\d+)/) {
            my ($type, $count) = ($1, $2);
            if ($type =~ /DFF/) { $ffs += $count; } else { $gates += $count; }
        }
    }
    close($sh);
}

print "==== UART run summary ====\n";
printf "%-16s %s\n", "$_:", ($sim{$_} // "n/a")
    for ("Bytes sent", "Bytes received", "Framing errors", "Errors", "RESULT");
if ($cells) {
    printf "%-16s %d\n", "Total cells:", $cells;
    printf "%-16s %d\n", "Flip-flops:", $ffs;
    printf "%-16s %d\n", "Logic gates:", $gates;
}

exit(($sim{"RESULT"} // "") eq "PASS" ? 0 : 1);
