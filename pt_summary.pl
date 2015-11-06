#!/tool/aticad/1.0/bin/perl
#!/usr/bin/perl -d
#use warnings;
use strict;
use POSIX;
use Data::Dumper;


#use Time::HiRes qw( time );
#my $start = time();
#my $end = time();
#printf("%.3f\n", $end - $start);

#if ($#ARGV > 0) { die "ERROR: component run directory needed\nUsage: component_timing_summary.pl <rundir>\n"; }
my $rpt = "$ARGV[0]";
my ($in_fh,$out_fh,$ID,$start,$end,$group,$slack,$flg,$cell,$file_name,$insertion_launch,$insertion_capture,$bfx,$cmb,$tmp);
my (@array,@arraytmp,@fan,@tran);
my (%hash,%hashtmp,%hashbin);
my $cell_prefix = "hp";
my $c = 0;

my $scale = 1/20.0;
my $numbins = 20;
my ($bin,$stars,$binsize,$max,$largest,$percent);

open ($in_fh, "gunzip -c $rpt |") or die "ERROR:: couldn't open file $rpt: $!";
while (<$in_fh>) {
  if ( /^  Startpoint/ ) {
    @array = split(/\s+/); $start = $array[2];
  } elsif ( /^  Endpoint/ ) { # ENDPOINT
    @array = split(/\s+/); $end = $array[2];
    while (<$in_fh>) {
      if ( / \($cell_prefix/ ) { 
        @array = split(/\s+/); $cell = $array[2];
        if ( $cell =~ /bfx/ || $cell =~ /inx/ ) {
          $bfx++;
        } elsif ( $cell =~ /msf/ ) { 
        } else {
          $cmb++;
        }
        if ($array[4] =~ /^\d/) { push(@tran,$array[3]); }
      } elsif ( / \(net\) / ) {
        @array = split(/\s+/); push(@fan, $array[3]);
      } elsif ( /^  clock network delay \(propagated\)/ ) {
        @array = split(/\s+/);
        if ($flg) {
          $insertion_capture = $array[5];
        } else {
          $insertion_launch = $array[5]; $flg = 1;
        }
      } elsif ( /^  Path Group/ ) {
        @array = split(/\s+/); $group = $array[3];
      } elsif ( /^  slack/ ) {
        @array = split(/\s+/); $slack = $array[-1];
        if ( $slack <= 0.0 ) {
          #PACK UP PATH INFO, reset vars
          $ID = "$slack$c";
          $hash{$ID}{slack} = $slack;
          $hash{$ID}{group} = $group;
          $hash{$ID}{bfx} = $bfx/2;
          $hash{$ID}{cmb} = $cmb/2;
          $start =~ s/\d+/*/g;
          $hash{$ID}{start} = $start;
          $end =~ s/\d+/*/g;
          $hash{$ID}{end} = $end;
          $hash{$ID}{skew} = int($insertion_launch - $insertion_capture);
          @arraytmp = sort { $a <=> $b } @fan;
          $hash{$ID}{fan} = $arraytmp[-1];
          @arraytmp = sort { $a <=> $b } @tran;
          $hash{$ID}{tran} = $arraytmp[-1];
          @fan=@tran=undef;$bfx=$cmb=$flg=0;
          $c++;
          last;
        } else { 
          @fan=@tran=undef;$bfx=$cmb=$flg=0;
          $c++;
          last;
        }
      }
    } #ENDPOINT WHILE
  } #ENDPOINT
} close $in_fh;

@array = split(/\//,$rpt); $file_name = $array[-1];
open ($out_fh, '>',"$file_name.summary") or die "ERROR:: couldn't open file $file_name.summary: $!";
printf $out_fh "%-9s%-20s%-5s%-5s%-5s%-9s%-10s%-120s%-120s%-1s", ("SLACK","GROUP","CMB","BFX","FAN","TRAN","SKEW","START","END","\n");
foreach my $key (sort {$a <=> $b} keys %hash) {
  printf $out_fh "%-9s%-20s%-5s%-5s%-5s%-9s%-10s%-120s%-120s%-1s", ($hash{$key}{slack},$hash{$key}{group},$hash{$key}{cmb},$hash{$key}{bfx},$hash{$key}{fan},$hash{$key}{tran},$hash{$key}{skew},$hash{$key}{start},$hash{$key}{end},"\n");
} close $out_fh;

@array = sort {$a <=> $b} keys %hash;
$binsize = -1*$array[0]/$numbins;
$binsize = int($binsize/1);
#find total paths in each bucket, percentage of each start point and endpoint
foreach my $key (sort {$a <=> $b} keys %hash) {
  $bin = int(-1*$key/$binsize);
  $hashbin{$bin}{total}++;
  $hashbin{$bin}{start}{$hash{$key}{start}}++;
  $hashbin{$bin}{end}{$hash{$key}{end}}++;
}


#Print HISTO
#@array = sort {$a <=> $b} keys %hashbin;
#$numbins = $array[-1];
printf "\nNumber of paths in each bin:\n";
for (my $i=$numbins; $i >= 0; $i--) {
  printf "%-5s < slack <= %-5s", (-$binsize*($i+1),-$binsize*($i));
  #$stars = "*" x int($hashbin{$i}{total}*$scale);
  printf "$hashbin{$i}{total}\n";
}

#Print START summary
printf "\nLargest STARTPOINT contributor for each bin:\n";
for (my $i=$numbins; $i >= 0; $i--) {
  printf "%-5s < slack <= %-5s", (-$binsize*($i+1),-$binsize*($i));
  $max = 0;
  if ($hashbin{$i}{total} > 0) {
    foreach my $key (keys %{$hashbin{$i}{start}}) {
      if ($hashbin{$i}{start}{$key} > $max) {
        $largest = $key;
        $max = $hashbin{$i}{start}{$key};
      }
    }
    $percent = int(100.0*$max/$hashbin{$i}{total});
    printf "%-120s %+3s\%\n", ($largest,$percent);
  } else { 
    printf "\n";
  }
}


#Print END summary
printf "\nLargest ENDPOINT contributor for each bin:\n";
for (my $i=$numbins; $i >= 0; $i--) {
  printf "%-5s < slack <= %-5s", (-$binsize*($i+1),-$binsize*($i));
  $max = 0;
  if ($hashbin{$i}{total} > 0) {
    foreach my $key (keys %{$hashbin{$i}{end}}) {
      if ($hashbin{$i}{end}{$key} > $max) {
        $largest = $key;
        $max = $hashbin{$i}{end}{$key};
      }
    }
    $percent = int(100.0*$max/$hashbin{$i}{total});
    printf "%-120s %+3s\%\n", ($largest,$percent);
  } else {
    printf "\n";
  }
}

