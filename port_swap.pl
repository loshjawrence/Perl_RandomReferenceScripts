#!/tool/aticad/1.0/bin/perl
#!/usr/bin/perl -d
#use warnings;
use strict;
use POSIX;
use Data::Dumper;
if ($#ARGV != 1) { die "ERROR: No report file given\nUsage: perl /home/jlawrence/bin/perl/port_swap.pl <timingfile> <locationfile>\n"; }
my $timfile = $ARGV[0];
my $locfile = $ARGV[1];
my ($in_fh,$infile,$out_fh,$bus);
my $PROX = 30.0;
my $DIST_POS = 100;
my $DIST_NEG = -100;
my $string = "";
my (@array);
my (%hash,%h_swap);
my $out_file = "port_swaps";
my ($bus1,$fanfar1,$size1,$min1,$max1,$trueloc1,$aveslack1,$proxhigh1,$proxlow1,$layer1);
my ($bus2,$fanfar2,$size2,$min2,$max2,$trueloc2,$aveslack2,$proxhigh2,$proxlow2,$layer2);

open ($in_fh, "<", $locfile) or die "ERROR:: couldn't open file $locfile: $!";
while (<$in_fh>) {
  if(/^Size /) {
    @array = split(/\s+/);
    $array[2] =~ s/://;
    $bus = $array[2];
    $hash{$bus}{size} =  $array[3];
    while(<$in_fh>) {
      if(/^a/){
        @array = split(/\s+/);
        $hash{$bus}{ave} =  $array[1];
      } elsif(/^mi/) { 
        @array = split(/\s+/);
        $hash{$bus}{min} =  $array[1];
      } elsif(/^ma/) { 
        @array = split(/\s+/);
        $hash{$bus}{max} =  $array[1];
      } elsif(/^l/) { 
        @array = split(/\s+/);
        $hash{$bus}{layer} =  $array[1];
      } elsif(/^Ave /) { 
        @array = split(/: /);
        $array[1] =~ s/ um.*$//;
        $array[1] =~ s/\n//;
        $hash{$bus}{fan} =  $array[1];
        $hash{$bus}{trueloc} = $hash{$bus}{ave} + $hash{$bus}{fan};
        last;
      }
    }
  }
}
close $in_fh;
open ($in_fh, "<", $timfile) or die "ERROR:: couldn't open file $timfile: $!";
while (<$in_fh>) {
  if(/^Size /) {
    @array = split(/\s+/);
    $bus = $array[2];
    $bus =~ s/:$//;
    while(<$in_fh>) {
      if(/^COULD /) { 
        last;
      } elsif(/^w/){
        @array = split(/\s+/);
        $hash{$bus}{wns} =  $array[1];
      } elsif(/^t/) { 
        @array = split(/\s+/);
        $hash{$bus}{tns} =  $array[1];
      } elsif(/^a/) { 
        @array = split(/\s+/);
        $hash{$bus}{aveslack} =  $array[4];
        last;
      } 
    }
  }
}
close $in_fh;
foreach my $key1 (sort keys %hash) { 
  if ($hash{$key1}{fan} > $DIST_POS || $hash{$key1}{fan} < $DIST_NEG) { $fanfar1 = 1; } else { $fanfar1 = 0; }
  if ($hash{$key1}{size} < 3 && $fanfar1) { 
    $string .= "$key1 (ave slack: $hash{$key1}{aveslack} size: $hash{$key1}{size} fan dist: $hash{$key1}{fan}) wants to live $hash{$key1}{trueloc} on $hash{$key1}{layer}\n";
    next;
  }
  $bus1 = $key1;
  $proxhigh1 = $hash{$bus1}{ave} + $PROX;
  $proxlow1 = $hash{$bus1}{ave} - $PROX;
  $trueloc1 = $hash{$bus1}{trueloc};
  $aveslack1 = int($hash{$bus1}{aveslack});
  $layer1 = $hash{$bus1}{layer};
  $size1 = $hash{$bus1}{size};
  $min1 = $hash{$bus1}{min};
  $max1 = $hash{$bus1}{max};
  foreach my $key2 (sort keys %hash) {
    if ($bus1 eq $key2) {
      next;
    }
    if ($hash{$key2}{size} < 3) {
      next;
    }
    if ($hash{$key2}{fan} > $DIST_POS || $hash{$key2}{fan} < $DIST_NEG) { $fanfar2 = 1; } else { $fanfar2 = 0; }
    $bus2 = $key2;
    $proxhigh2 = $hash{$bus2}{ave} + $PROX;
    $proxlow2 = $hash{$bus2}{ave} - $PROX;
    $trueloc2 = $hash{$bus2}{trueloc};
    $aveslack2 = int($hash{$bus2}{aveslack});
    $layer2 = $hash{$bus2}{layer};
    $size2 = $hash{$bus2}{size};
    $min2 = $hash{$bus2}{min};
    $max2 = $hash{$bus2}{max};
    if ($proxlow1 < $trueloc2 && $proxhigh1 > $trueloc2 && $proxlow2 < $trueloc1 && $proxhigh2 > $trueloc1 && $layer1 eq $layer2 && ($fanfar1 || $fanfar2)) {
      if (exists $h_swap{"$bus2 $bus1"}) {
      } else {
        $h_swap{"$bus1 $bus2"} = 1;
        $string .= "$bus1 (ave slack: $aveslack1 size: $size1 min: $min1 max: $max1 fan dist: $hash{$bus1}{fan}) wants to swap with $bus2 (ave slack: $aveslack2 size: $size2 min: $min2 max: $max2 fan dist: $hash{$bus2}{fan}) on $layer1\n";
      }
    } elsif (exists $h_swap{"$bus1"}) {
    } elsif ($fanfar1) {
      $h_swap{"$bus1"} = 1;
      $string .= "$bus1 (ave slack: $aveslack1 size: $size1 min: $min1 max: $max1 fan dist: $hash{$bus1}{fan}) wants to live $trueloc1 on $layer1\n";
    } 
  }
}

open ($out_fh, ">", $out_file) or die "ERROR:: couldn't open file $out_file: $!";
print $out_fh $string;
