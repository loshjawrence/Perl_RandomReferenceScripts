#!/tool/aticad/1.0/bin/perl
#!/usr/bin/perl -d
#use warnings;
use strict;
use POSIX;
use Data::Dumper;

#Edit cron: (runs monday at noon)
#ssh atlvcron01
#crontab -e
#0 14 * * 1 /home/jlawrenc/bin/perl/flops.pl
#Table: Crontab Fields and Allowed Ranges (Linux Crontab Syntax)
#Field	Description	Allowed Value
#MIN	Minute field	0 to 59
#HOUR	Hour field	0 to 23
#DOM	Day of Month	1-31
#MON	Month field	1-12
#DOW	Day Of Week	0-6
#CMD	Command	Any command to be executed.
#http://www.thegeekstuff.com/2009/06/15-practical-crontab-examples/

if ($#ARGV > 0) { die "ERROR:\nUsage: /home/jlawrence/bin/perl/flops.pl\n"; }
my $pubdir = "/proj/asdf_asdf_pub1/asdf/publish/base_asdf/tile/";
my ($inst,$in_fh,$infile,$out_file,$histout_file,$out_fh,$rtl,$publish,$floorplan,$timedate,$weekday,$target);
my $reportcellprefix = "   asdf";
my $cellprefix = "asdf";
my (@array);
my (%hash,%hasht,%hashc);
$hasht{flops} = $hasht{flops_x1} = $hasht{flops_x2} = $hasht{flops_asdf} = $hasht{flops_asdf} = $hasht{flops_asdf} = $hasht{flops_asdf} = $hasht{flops_asdf} = $hasht{flops_asdf} = $hasht{flops_asdf} = $hasht{flops_asdf} = $hasht{flops_nonasdf} = $hasht{cells_asdf} = $hasht{cells_asdf} = $hasht{cells_asdf} = $hasht{cells} = 0;
$hashc{flops} = $hashc{flops_x1} = $hashc{flops_x2} = $hashc{flops_asdf} = $hashc{flops_asdf} = $hashc{flops_asdf} = $hashc{flops_asdf} = $hashc{flops_asdf} = $hashc{flops_asdf} = $hashc{flops_asdf} = $hashc{flops_asdf} = $hashc{flops_nonasdf} = $hashc{cells_asdf} = $hashc{cells_asdf} = $hashc{cells_asdf} = $hashc{cells} = 0;
my $fpout_file = "$pubdir"."asdf_asdfflops.rpt";
my $asdfout_file = "$pubdir"."asdf_asdfflops.rpt";
my $asdfout_file = "$pubdir"."asdf_asdfflops.rpt";
my $fphistout_file = "$pubdir"."history_asdf_asdfflops.rpt";
my $asdfhistout_file = "$pubdir"."history_asdf_asdfflops.rpt";
my $asdfhistout_file = "$pubdir"."history_asdf_asdfflops.rpt";

#Go to asdf publish area and add flop report of latest tile publishes. 
my %TILENAMES = ( 
                    #asdf => ['asdf','asdf','asdf','asdf'],
                    #asdf => ['asdf0','asdf0','asdf0'],
                    asdf => ['asdf','asdf','asdf','asdfsce','asdff0','asdf0','asdfasdf0','asdfasdf','asdf']
                );

foreach my $component (sort keys %TILENAMES) {
  if ($component eq "asdf") { $out_file = $fpout_file; 
  } elsif ($component eq "asdf") { $out_file = $asdfout_file;
  } elsif ($component eq "asdf") { $out_file = $asdfout_file; }
  open ($out_fh, ">", $out_file) or die "ERROR:: couldn't open file $out_file: $!";

  $timedate = $1." ".$2." ".$3." ".$5." ".$4 if (`date` =~ /(\S+)\s+(\S+)\s+(\d+)\s+([\d:]+)\s+.*[MPE][DS]T\s+(\d+)$/);
  $weekday = $1;

  printf $out_fh "%s\n%-15s%-70s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s\n", ($timedate,$component,"RTL","Floorplan","Publish","Total Flops","asdf Flops","asdf Flops","asdf Flops","asdf Flops","asdf Flops","asdf Flops","asdf Flops","asdf Flops","asdf Flops","asdf Flops","Non-asdf Flops","Total Cells","asdf Cells","asdf Cells","asdf Cells");

  foreach my $key (keys %hashc) { $hashc{$key} = 0; }

  foreach my $tile (sort @{$TILENAMES{$component}}) {
    open ($in_fh, "$pubdir$tile/latest/release.notes") or die "ERROR:: couldn't open file $pubdir$tile/latest/release.notes:$!";
    while (<$in_fh>) {
      if(/^Version\:/) { @array = split(/\s+/); $publish = $array[1];
      } elsif(/^Target\:/) {
        if(/reroute/)    { $target = "asdf";
        } elsif(/route/) { $target = "asdf";
        } elsif(/place/) { $target = "asdf"; }
      } elsif(/^FLOORPLAN_DIR\:/) { @array = split(/\//); $floorplan = $array[8];
      } elsif(/^RTL_TAG\:/) { @array = split(/\s+/); $rtl = $array[1]; }
    }
    close $in_fh;

    %hash = ();
    foreach my $key (keys %hasht) { $hasht{$key} = 0; }
    
    $infile = "$pubdir$tile/latest/rpts/$target/asdf_utilization.rpt.gz";
    open ($in_fh, "gunzip -c $infile |") or die "ERROR:: couldn't open file $infile: $!";

    while (<$in_fh>) {
      if(/^$reportcellprefix.*x/) {
        @array = split(/\s+/);
        $hash{$array[1]} = $array[3];
      }
    }
        
    foreach my $cell (keys %hash) {
      $inst = $hash{$cell};
      if ($cell =~ /^${cellprefix}.*msf.*x/ || $cell =~ /^${cellprefix}.*fq.*x/) { #flop
        $hasht{flops} += $inst;
        if ($cell =~/asdf/)          { $hasht{flops_asdf}   += $inst;    }
        if ($cell =~/asdf/)          { $hasht{flops_asdf}   += $inst;    }
        if ($cell =~/asdf/)          { $hasht{flops_asdf}   += $inst;    }
        if ($cell =~/asdf/)          { $hasht{flops_asdf}   += $inst;    }
        if ($cell =~/f[n]?qb/)       { $hasht{flops_asdf}  += $inst;    }
        if ($cell =~/asdf/)          { $hasht{flops_asdf} += $inst;    }
        if ($cell =~/asdf$/)           { $hasht{flops_asdf} += $inst;    }
        if ($cell =~/asdf[c]?$/)       { $hasht{flops_asdf}  += $inst;    }
        if ($cell =~/asdf[c]?$/)       { $hasht{flops_asdf}  += $inst;    }
        if ($cell =~/asdf/) { 
          $hasht{flops_asdf} += $inst; 
          print "$component : $tile : $cell\n";
        }
      }
      unless ($cell =~/tap|boundary/) { #if not
        if ($cell =~/asdf$/)         { $hasht{cells_asdf} += $inst;     }
        if ($cell =~/asf[c]?$/)     { $hasht{cells_asdf}  += $inst;     }
        if ($cell =~/asdf[c]?$/)     { $hasht{cells_asdf}  += $inst;     }
        #if ($cell =~/^$cellprefix/){ $hasht{cells}      += $inst;     }
      }
    }
    $hasht{flops_asdf} = $hasht{flops} - $hasht{flops_nonasdf};
    $hasht{cells}      = $hasht{cells_asdf} + $hasht{cells_asdf} + $hasht{cells_asdf};
    foreach my $metric (keys %hasht) { $hashc{$metric} += $hasht{$metric}; }

    close $in_fh;
    printf $out_fh "%-15s%-70s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s\n", ($tile,$rtl,$floorplan,$publish,$hasht{flops},$hasht{flops_x1},$hasht{flops_x2},$hasht{flops_asdf},$hasht{flops_asdf},$hasht{flops_asdf},$hasht{flops_asdf},$hasht{flops_asdf},$hasht{flops_asdf},$hasht{flops_asdf},$hasht{flops_asdf},$hasht{flops_asdf},$hasht{cells},$hasht{cells_asdf},$hasht{cells_asdf},$hasht{cells_asdf});
  }
  printf $out_fh "-" x 345;
  printf $out_fh "\n%-15s%-70s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s\n\n\n", ("TOTALS","","","",$hashc{flops},$hashc{flops_x1},$hashc{flops_x2},$hashc{flops_asdf},$hashc{flops_asdf},$hashc{flops_asdf},$hashc{flops_asdf},$hashc{flops_asdf},$hashc{flops_asdf},$hashc{flops_asdf},$hashc{flops_asdf},$hashc{flops_asf},$hashc{cells},$hashc{cells_asdf},$hashc{cells_asdf},$hashc{cells_asdf});
   
  #Update history file on monday
  if ($weekday =~ /Mon/) {
    if      ($component eq "asdf") { $histout_file = $fphistout_file; 
    } elsif ($component eq "asdf") { $histout_file = $asdfhistout_file;
    } elsif ($component eq "asdf") { $histout_file = $asdfhistout_file; }
    `cat $out_file >> $histout_file`;
  }

}

