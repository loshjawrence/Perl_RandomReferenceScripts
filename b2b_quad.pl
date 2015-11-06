#!tool/pandora64/bin/perl 
#!/usr/bin/perl -d
use warnings;
use strict;
use Data::Dumper;
if ($#ARGV < 0) {die "ERROR: I need tile your name.\n";}
my $tile = $ARGV[0];
my $B2B = "/proj/asdfa_timing1/timing/B2B_paths/B2B_paths.summary";
my $in_fh;
my $out_fh;
my %b2b_hash;
my @array;
my $quad_fixto = 15;
my $flop_fixto = 6;
my $instance;
my $fix_amount;
#my $i;
open ($in_fh, $B2B) or die "ERROR:: couldn't open file $B2B: $!";
while (<$in_fh>) {
  if(/$tile\/${tile}_SLM/){
    $_ =~ s/^\s+//;
    @array = split(/\s+/);
    $instance = $array[0];
    $fix_amount = $array[1];
    if(!$b2b_hash{$instance}) { #doesnt exist
      $b2b_hash{$instance} = $fix_amount;
      #$b2b_hash{$instance}{count} = 1;
    } else { #exists
      #$b2b_hash{$instance}{count} = $b2b_hash{$instance}{count} + 1;
      if($b2b_hash{$instance} < $fix_amount) {
        $b2b_hash{$instance} = $fix_amount;
      }
    }
  }
}
close $in_fh;

open($out_fh, '>', "b2b_report_timing.tcl") or die "ERROR:: couldn't open file b2b_report_timing.tcl: $!";
printf $out_fh "redirect b2b_timing.rpt {\n";
foreach my $cell (keys %b2b_hash) {
  if ($cell =~ "Q4_reg") { #quad
    for (my $i=0; $i<4; $i++) {
      printf $out_fh "report_timing -thr $cell\/D$i\n";
      printf $out_fh "report_timing -thr $cell\/QB$i\n";
    }
  } else { #flop
    printf $out_fh "report_timing -thr $cell\/D\n";
    printf $out_fh "report_timing -thr $cell\/QB\n";
  }
}
printf $out_fh "}\n";
