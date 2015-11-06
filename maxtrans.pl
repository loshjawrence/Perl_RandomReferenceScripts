#!tool/pandora64/bin/perl 
#!/usr/bin/perl -d
use warnings;
use strict;
use Data::Dumper;
#if ($#ARGV < 0) {  die "ERROR: No file given\nUsage: perl maxtrans.pl maxtransfile\n"; }
#create maxtransfile using:
my $maxtransfile_pre = "maxtransfile_pre";
my $maxtransfile = "maxtransfile";
my $maxtransnets = "maxtransnets";
my $maxtransfile_sort = "maxtransfile_sort";
my $maxtransnets_sort = "maxtransnets_sort";

my $in_fh;
my $out_fh;
my @array;
my @hier;
my $net;
my $drv;
my $rcv;
my %drvrpt;
my %rcvrpt;
system(sprintf"cat /proj/xv_scratch_timing1/tracker_html/asdf_1m/constraint_reports/*/slm_report/asdf?.max_transition* | grep asdf_RPT > $maxtransfile_pre");
open ($in_fh, $maxtransfile_pre) or die "ERROR:: couldn't open file $maxtransfile_pre: $!";
while (<$in_fh>) { #base on the format of the dynamic stat file
  chomp; #remove \n
  $_ =~ s/^\s+//;#remove starting whitespace
  @array = split(/\s+/);# split based on whitespace
  $net = $array[5];
  $drv = $array[7];
  $rcv = $array[8];
  $_ =~ s/^.*$array[4]//;
  $_ =~ s/^\s+//;
  if($drv =~ /asdf_RPT/) { 
    $drvrpt{$drv} = $_;
  }
  if($rcv =~ /SLM_RPT/) { 
    $rcvrpt{$rcv} = $_;
  }
}
close $in_fh;

open($out_fh, '>', $maxtransfile) or die "ERROR:: couldn't open file $maxtransfile: $!";
foreach my $key (keys %drvrpt) {
  printf $out_fh "%s\n", ($drvrpt{$key});
}
close $out_fh;

open($in_fh, $maxtransfile) or die "ERROR:: couldn't open file $maxtransfile: $!";
open($out_fh, '>', $maxtransnets) or die "ERROR:: couldn't open file $maxtransnets: $!";
while(<$in_fh>) {
  chomp; #remove \n
  $_ =~ s/^\s+//;#remove starting whitespace
  @array = split(/\s+/);# split based on whitespace
  $net = $array[0];
  @hier = split(/\//, $net);
  $net = $hier[$#hier];
  $net =~ s/_\d+_.*$//;#remove trailing things like _23_ to end of string
  $net =~ s/___*.*$//;#remove multiple underscrores to end of string
  printf $out_fh "%s\n", ($net);
}
close $in_fh;
close $out_fh;
system(sprintf"cat $maxtransfile | sort > $maxtransfile_sort");
system(sprintf"cat $maxtransnets | sort -u > $maxtransnets_sort");
system(sprintf"rm -f $maxtransnets");
system(sprintf"rm -f $maxtransfile_pre");
system(sprintf"rm -f $maxtransfile");






