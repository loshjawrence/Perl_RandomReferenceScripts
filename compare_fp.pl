#!/tool/aticad/1.0/bin/perl
#!/usr/bin/perl -d
#use warnings;
use strict;
use POSIX;
use Data::Dumper;

#/home/jlawrenc/bin/perl/compare_io.pl -d /proj/asdf_l3_scratch_pd1/asdf/asdf/jlawrenc/asdf_126669_fp54/main/pd/tiles/asdf_run_asdf_Jul01_1250_GUI_7811 /proj/asdf_asdf_scratch_pd1/asdf/asdf/jlawrenc/asdf_128924_fp58/main/pd/tiles/asdfTopClone_run_asdf_Jul24_1010_GUI_1418

if ($#ARGV < 1) { die "ERROR:\nUsage: /home/jlawrence/bin/perl/compare_io.pl <old_run> <new_run>\n"; }
my ($tmp, $oldrun, $newrun);
if ($#ARGV == 2) { ($tmp, $oldrun, $newrun) = @ARGV; 
} else { ($oldrun, $newrun) = @ARGV; }

my ($in_fh,$next,$tile,$string_output,$pin);
my $DIST = 50.0;#pin displacement theshold um
my $PS = 50.0;#sdc delta threshold ps
my $sdc = "asdf";
my (@array);
my (%hashold,%hashnew,%hashdiff_loc,%hashdiff_sdc,%hashdiff_notfound);
$string_output .= "oldrun: $oldrun\nnewrun: $newrun\n";

@array = split(/\//,$oldrun);
my $old = $array[-1];
@array = split(/\//,$newrun);
my $new = $array[-1];

sub processDef {
my $stop = 1;
  if (@_ < 2) { 
    print "ERROR: &processDef needs a run directory, tile, and hash passed to it.\n";
  } else { 
    my($run,$tile,%hash) = @_;
    open ($in_fh, "gunzip -c $run/cell/$tile/$tile.def.gz |") or die "ERROR:: couldn't open file $run/cell/$tile/$tile.def.gz: $!";
    while (<$in_fh>) { #1
      if (/^PINS/) {
        while (<$in_fh>) { #2
          if (/^-/) { 
            @array = split(/\s+/); $pin = $array[1];

            $next = <$in_fh>;
            if ($next =~ /LAYER/) {
              @array = split(/\s+/,$next); 
              $hash{$pin}{layer} = $array[3];
            } elsif ($next =~ /^ ;/) { 
              $hash{$pin}{layer} = "NOT PLACED";
              $hash{$pin}{x} = "NOT PLACED";
              $hash{$pin}{y} = "NOT PLACED";
              next;
            }

            $next = <$in_fh>;
            @array = split(/\s+/,$next); 
            $hash{$pin}{x} = $array[4];
            $hash{$pin}{y} = $array[5];
          } elsif (/^END/) { last; } #2
        }
        last; #1
      }
    } close $in_fh; 
    return %hash;
  } #else
} #sub

#Get list of tiles
my $tmp = `ls $oldrun/cell`;
my @tilearray = split(/\s+/, $tmp);


#Populate hashes with pin info
foreach $tile (sort @tilearray) {
  %hashold = &processDef($oldrun, $tile, %hashold);
  %hashnew = &processDef($newrun, $tile, %hashnew);
}


#Get typ corner sdc info for oldrun
foreach $tile (@tilearray) {
  open ($in_fh, "gunzip -c $oldrun/cell/$tile/$tile.$sdc.sdc.gz |") or die "ERROR:: couldn't open file $oldrun/cell/$tile/$tile.$sdc.sdc.gz: $!";
  while (<$in_fh>) { 
    if (/^set_input_delay |^set_output_delay /) { 
      @array = split(/\s+/); $pin = $array[9]; $pin = substr($pin, 0, -1); #shave off last char
      $hashold{$pin}{sdc} = $array[7];
    }
  }
}



#Get typ corner sdc info for newrun
foreach $tile (@tilearray) {
  open ($in_fh, "gunzip -c $newrun/cell/$tile/$tile.$sdc.sdc.gz |") or die "ERROR:: couldn't open file $newrun/cell/$tile/$tile.$sdc.sdc.gz: $!";
  while (<$in_fh>) { 
    if (/^set_input_delay |^set_output_delay /) { 
      @array = split(/\s+/); $pin = $array[9]; $pin = substr($pin, 0, -1); #shave off last char
      $hashnew{$pin}{sdc} = $array[7];
    }
  }
}



#COMPARE HASHES
foreach my $key (keys %hashnew) { 
  if (exists $hashold{$key}) {
    #if ($hashold{$key}{layer} ne $hashnew{$key}{layer}) { $string_output .= "$key layer: $hashold{$key}{layer} -> $hashnew{$key}{layer}\n"; }

    $tmp = ($hashnew{$key}{x} - $hashold{$key}{x})/1000.0;
    if ($tmp > $DIST || $tmp < -$DIST) { 
      $hashdiff_loc{$key}{xdelta} =  $tmp; 
      $hashdiff_loc{$key}{ydelta} = ($hashnew{$key}{y} - $hashold{$key}{y})/1000.0;
      next;
    }

    $tmp = ($hashnew{$key}{y} - $hashold{$key}{y})/1000.0;
    if ($tmp > $DIST || $tmp < -$DIST) { 
      $hashdiff_loc{$key}{xdelta} = ($hashnew{$key}{x} - $hashold{$key}{x})/1000.0;
      $hashdiff_loc{$key}{ydelta} = $tmp; 
    }

    $tmp = $hashnew{$key}{sdc} - $hashold{$key}{sdc};
    if ($tmp > $PS || $tmp < -$PS) { 
      $hashdiff_sdc{$key}{sdcdelta} = $tmp; 
    }

  } else { 
    $hashdiff_notfound{$key}{notfound} = $old;
  }
}
foreach my $key (keys %hashold) { 
  if (exists $hashnew{$key}) { #already processed above.
  } else { 
    $hashdiff_notfound{$key}{notfound} = $new;
  }
}
`rm -rf /home/jlawrenc/fpdiff/*`;
open (my $out_fh, '>', "/home/jlawrenc/fpdiff/scratch") or die "ERROR:: couldn't open file scratch: $!";
foreach my $key (sort keys %hashdiff_loc) {
  printf $out_fh "%-120s%-15s%-15s%-1s" , ($key, $hashdiff_loc{$key}{xdelta}, $hashdiff_loc{$key}{ydelta}, "\n");
} close $out_fh;
open (my $out_fh, '>', "/home/jlawrenc/fpdiff/fpdiff_x") or die "ERROR:: couldn't open file fpdiff_x: $!";
printf $out_fh "%-120s%-15s%-15s%-1s" , ("PORT", "X_DELTA", "Y_DELTA", "\n");
close $out_fh;
`cp /home/jlawrenc/fpdiff/fpdiff_x /home/jlawrenc/fpdiff/fpdiff_y`;
`cat /home/jlawrenc/fpdiff/scratch | grep -v SDI_ | grep -v SDO_ | sort -nrk 2 >> /home/jlawrenc/fpdiff/fpdiff_x`;
`cat /home/jlawrenc/fpdiff/scratch | grep -v SDI_ | grep -v SDO_ | sort -nrk 3 >> /home/jlawrenc/fpdiff/fpdiff_y`;

open (my $out_fh, '>', "/home/jlawrenc/fpdiff/scratch") or die "ERROR:: couldn't open file scratch: $!";
foreach my $key (sort keys %hashdiff_sdc) {
  printf $out_fh "%-120s%-15s%-1s" , ($key, $hashdiff_sdc{$key}{sdcdelta}, "\n");
} close $out_fh;
open (my $out_fh, '>', "/home/jlawrenc/fpdiff/fpdiff_sdc") or die "ERROR:: couldn't open file fpdiff_sdc: $!";
printf $out_fh "%-120s%-15s%-1s" , ("PORT", "SDC_DELTA", "\n");
close $out_fh;
`cat /home/jlawrenc/fpdiff/scratch | grep -v SDI_ | grep -v SDO_ | sort -nrk 2 >> /home/jlawrenc/fpdiff/fpdiff_sdc`;

open (my $out_fh, '>', "/home/jlawrenc/fpdiff/scratch") or die "ERROR:: couldn't open file scratch: $!";
foreach my $key (sort keys %hashdiff_notfound) {
  printf $out_fh "%-120s%-15s%-1s" , ($key, $hashdiff_notfound{$key}{notfound}, "\n");
} close $out_fh;
open (my $out_fh, '>', "/home/jlawrenc/fpdiff/fpdiff_notfound") or die "ERROR:: couldn't open file fpdiff_notfound: $!";
printf $out_fh "%-120s%-15s%-1s" , ("PORT", "NOT_FOUND", "\n");
close $out_fh;
`cat /home/jlawrenc/fpdiff/scratch | grep -v SDI_ | grep -v SDO_ | sort -nrk 2 >> /home/jlawrenc/fpdiff/fpdiff_notfound`;
`rm -rf /home/jlawrenc/fpdiff/scratch`;
