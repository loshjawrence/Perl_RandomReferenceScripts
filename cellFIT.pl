#!tool/pandora64/bin/perl 
#!/usr/bin/perl -d
use warnings;
use strict;
use Data::Dumper;
if ($#ARGV < 0) {die "ERROR: I need tile your name.\n";}
my $tile = $ARGV[0];
my $sigem = "$ENV{PWD}/rpts/SignalEMPost/$tile.sigem.rpt";
my $in_fh;
my $out_fh;
my %upsize_hash;
my $flg = 0;
my $instance;
my $cell;
my @array;
my $stdcellprefix = "xd";
open ($in_fh, $sigem) or die "ERROR:: couldn't open file $sigem: $!";
while (<$in_fh>) {
  if(/INSTNAME/) {
    while (<$in_fh>) {
      if(/$tile/){
        $_ =~ s/^\s+//;
        @array = split(/\s+/);
        $instance = $array[0];
        $instance =~ s/:.*$//;#remove pin
        $instance =~ s/^.*$tile\///;#remove chiplet hierarchy 
      }
      last;           
    }
  }#if INSTNAME
  if(/upsized to/) { 
    while (<$in_fh>) {
      if(/$stdcellprefix/){
        $_ =~ s/^\s+//;
        @array = split(/\s+/);
        $cell = $array[0];
        $cell =~ s/:.*$//;#remove colon
        $upsize_hash{$instance} = $cell;
      }
      last;
    }
  }#if upsized to
}
close $in_fh;

open($out_fh, '>', "cellFIT_upsize.tcl") or die "ERROR:: couldn't open file changelink.tcl: $!";
printf $out_fh "amd_delete_filler\n";
printf $out_fh "set STDCELL [asdfPROC_get_libname STDCELL]\n";
foreach my $FITcell (keys %upsize_hash) {
  printf $out_fh "change_link [get_cells $FITcell] \$STDCELL\/$upsize_hash{$FITcell}\n"
}
printf $out_fh "set FITcells [get_cells {\n";
foreach my $FITcell (keys %upsize_hash) {
  printf $out_fh "$FITcell\n"
}
printf $out_fh "}]\n";
printf $out_fh "legalize_placement -eco -cells [get_cells \$FITcells]\n";
printf $out_fh "amd_add_filler\n";
printf $out_fh "set FITcells_nets [get_nets -of [get_pins -of [get_cells \$FITcells]]]\n";
printf $out_fh "route_zrt_eco -open_net_driven true -reroute modified_nets_first_then_others -nets \$FITcells_nets\n";
printf $out_fh "save_mw_cel -increase_version\n";
printf $out_fh "save_interactive_design -design asdf\n";
 
