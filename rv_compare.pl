#!tool/pandora64/bin/perl 
#!/usr/bin/perl -d
#use warnings;
use strict;
use Data::Dumper;
if ($#ARGV < 0) {  die "ERROR: No inst file given\nUsage: need nonquad dir and a quad dir\n"; }
my $quaddir = "$ARGV[0]"."/data/rtl.info";
my $nonquaddir = "$ARGV[1]"."/data/rtl.info";
my %quad;
my %nonquad;
my $in_fh;
my $out_fh;
my @fields;
my $rv;
my $instance;
my $num = 0;
my $bit = 0;
my $flg = 0;
open ($in_fh, $nonquaddir) or die "ERROR:: couldn't open file $nonquaddir: $!";
while (<$in_fh>) {
  if(/Q_reg/) {
    @fields = split(/\s+/);
    $rv = substr $fields[1],-1,1;#grab last character of $fields[1]
    $instance = $fields[0];
    $instance =~ s/\/Q_reg.*$//;
    $num = $fields[0];
    $num =~ s/^.*reg_//; 
    $nonquad{$instance}{$num} = $rv;
  }
}
close $in_fh;


open ($in_fh, $quaddir) or die "ERROR:: couldn't open file $quaddir: $!";
while (<$in_fh>) {
  if(/Q4_reg/) {
    @fields = split(/\s+/);
    $rv = substr $fields[1],-1,1;#grab last character of $fields[1]
    $instance = $fields[0];
    $instance =~ s/\/Q4_reg.*$//;
    $num = $fields[0];
    $num =~ s/^.*reg_//;
    for(my $i = 0; $i < 4; $i++) {
      $bit = $num + $i;
      if(!(exists $nonquad{$instance}{$bit})) {
        if($i==0) {
          printf "quads were enabled for %s in your 'nonquad' run.\n", $instance; 
          last;
        } else {
          printf "bit %d doesn't exist in %s but %s has been created for it.\n", $bit, $instance, $fields[0];
        }
      } 
      if($nonquad{$instance}{$bit} != $rv && !($nonquad{$instance}{$bit} eq "X")) {
        $flg = 1;
        printf "RESET VALUE MISMATCH: %s rv= %d %s/Q_reg_%s rv= %d\n", $fields[0], $rv, $instance, $bit, $nonquad{$instance}{$bit};
      }
    }
  }
}
close $in_fh;

