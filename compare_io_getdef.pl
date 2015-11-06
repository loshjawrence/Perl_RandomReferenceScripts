#!/tool/aticad/1.0/bin/perl
#!/usr/bin/perl -d
#use warnings;
use strict;
use POSIX;
use Data::Dumper;

#/home/jlawrenc/bin/perl/compare_io.pl -d /proj/asdf_l3_scratch_pd1/asdf/asdf/jlawrenc/asdf_126669_fp54/main/pd/tiles/asdf_run_asdf_Jul01_1250_GUI_7811 /proj/asdf_l3_scratch_pd1/asdf/asdf/jlawrenc/asdf_128924_fp58/main/pd/tiles/asdfTopClone_run_asdf_Jul24_1010_GUI_1418

if ($#ARGV < 1) { die "ERROR:\nUsage: /home/jlawrence/bin/perl/compare_io.pl <good_run> <unknown_run>\n"; }
my ($tmp, $run1, $run2,$next);
if ($#ARGV == 2) { ($tmp, $run1, $run2) = @ARGV; 
} else { ($run1, $run2) = @ARGV; }

my ($in_fh,$infile,$string_output,$pin,$x,$y,$delay);
my $DIST = 50.0;
my $PS = 50.0;
my $def_file = "data/GetDef.def.gz";
my $constraint_dir = "data/sdc/setup.";
my (@array);
my (%hash1,%hash2);
$string_output .= "run1: $run1\nrun2: $run2\n";

sub processDef {
  if (@_ != 1) { 
    print "ERROR: &processDef needs a run directory and hash passed to it.\n";
  } else { 
    my($run,%hash) = @_;
    open ($in_fh, "gunzip -c $run/$def_file |") or die "ERROR:: couldn't open file $run/$def_file: $!";
    while (<$in_fh>) { #1
      if (/^PINS/) {
        while (<$in_fh>) { #2
          if (/^END/) { last; #2
          } elsif (/^- /) {
            @array = split(/\s+/); $pin = $array[1];
            $next = <$in_fh>;
            if ($next =~ /^  \+/) {
              @array = split(/\s+/,$next);
              $hash{$pin}{layer} = $array[3];
              $next = <$in_fh>;
              @array = split(/\s+/,$next);
              $hash{$pin}{x} = $array[4];
              $hash{$pin}{y} = $array[5];
            } else { 
              $hash{$pin}{layer} = "NOT PLACED";
              $hash{$pin}{x} = "NOT PLACED";
              $hash{$pin}{y} = "NOT PLACED";
            }
          }
        }
        last; #1
      }
    } close $in_fh; 
    return %hash;
  } #else
} #sub


%hash1 = &processDef($run1, %hash1);
%hash2 = &processDef($run2, %hash2);


my @files = glob("$run1/$constraint_dir*.sdc");
foreach my $con_file (@files) {
  open ($in_fh, $con_file) or die "ERROR:: couldn't open file $con_file: $!";
  @array = split(/\//, $con_file);
  my $mode_corner = $array[-1];
  while (<$in_fh>) { 
    if (/^set_input_delay |^set_output_delay /) { 
      @array = split(/\s+/); $pin = $array[9]; $pin = substr($pin, 0, -1); #shave off last char
      $hash1{$pin}{$mode_corner} = $array[7];
    }
  }
  close $in_fh;
}

my @files = glob("$run2/$constraint_dir*.sdc");
foreach my $con_file (@files) {
  open ($in_fh, $con_file) or die "ERROR:: couldn't open file $con_file: $!";
  @array = split(/\//, $con_file);
  my $mode_corner = $array[-1];
  while (<$in_fh>) { 
    if (/^set_input_delay |^set_output_delay /) { 
      @array = split(/\s+/); $pin = $array[9]; $pin = substr($pin, 0, -1); #shave off last char
      $hash2{$pin}{$mode_corner} = $array[7];
    }
  }
  close $in_fh;
}

#COMPARE HASHES
foreach my $key (keys %hash2) { 
  if (exists $hash1{$key}) {

    if ($hash1{$key}{layer} ne $hash2{$key}{layer}) { $string_output .= "$key layer: $hash1{$key}{layer} -> $hash2{$key}{layer}\n"; }
    $tmp = ($hash2{$key}{x} - $hash1{$key}{x})/1000.0;
    if ($tmp > $DIST || $tmp < -$DIST) { $string_output .= "$key xdelta: $tmp\n"; }
    $tmp = ($hash2{$key}{y} - $hash1{$key}{y})/1000.0;
    if ($tmp > $DIST || $tmp < -$DIST) { $string_output .= "$key ydelta: $tmp\n"; }
    my @arraytmp = keys %{$hash1{$key}};
    foreach my $stat (keys %{$hash1{$key}}) {
      if ($stat =~/Func/ || $stat =~/Scan/) {
        $tmp = $hash2{$key}{$stat} - $hash1{$key}{$stat};
        if ($tmp > $PS || $tmp < -$PS) { $string_output .= "$key delta $stat: $tmp\n"; }
      }
    }

  } else { 
    $string_output .= "$key not found in run1\n";
  }
}

foreach my $key (keys %hash1) { 
  if (exists $hash2{$key}) { #do nothing
  } else { 
    $string_output .= "$key not found in run2\n";
  }
}
open (my $out_fh, '>', "all") or die "ERROR:: couldn't open file all: $!";
print $out_fh $string_output;
close $out_fh;
`cat all | grep -v SDI_ | grep -v SDO_ | grep FuncTT1p0 | sort > functt1p0`;
`cat all | grep -v SDI_ | grep -v SDO_ | grep found | sort > notfound`;
`cat all | grep -v SDI_ | grep -v SDO_ | grep xdelta | sort > xdelta`;
`cat all | grep -v SDI_ | grep -v SDO_ | grep ydelta | sort > ydelta`;
