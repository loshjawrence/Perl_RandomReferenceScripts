#!/tool/aticad/1.0/bin/perl
#!/usr/bin/perl -d
#use warnings;
use strict;
use POSIX;
use Data::Dumper;

#/home/jlawrenc/bin/perl/compare_statepoints.pl 
#Getopt::Long Getopt::Std for invocation options
use Getopt::Long;
my ($target, $statepoints, $runs);

 
GetOptions(
    '--target=s' => \$target,
    '--statepoints=s' => \$statepoints,
    '--runs=s' => \$runs,
) or die "Usage: /home/jlawrenc/bin/perl/compare_statepoints.pl -t target -s \"s1 s2 etc\" -r \"r1 r2 etc\"\n"; 

my ($in_fh,$infile,$output,$wns,$tns,$tmp,$slack,$next,$from,$to,$run,$line,$to_flag,$from_flag,$isbranch);
my (@tmparray,@runarray,@sparray);
my (%hashsp);

@runarray = split(/\s+/, $runs); 
@sparray = split(/\s+/, $statepoints); 

for ( @sparray ) { s/\[/\\\[/g; }
for ( @sparray ) { s/\]/\\\]/g; }
#MAIN LOOP: fetch to/from timing failures on all statepoints in all runs for specified target 
for (@runarray) {
  $run = $_;
  if ($run =~ /\//) { $isbranch = "";
  } else { $isbranch = "../"; }
  open ($in_fh, "gunzip -c $isbranch$run/rpts/$target/report_timing_max.rpt.gz |") or die "ERROR:: couldn't open file ../$run/rpts/$target/report_timing_max.rpt.gz: $!";
  while (<$in_fh>) {
    $line = $_;
    if (/^  Startpoint/) {
      for (@sparray) { 
        if ($line =~ /$_/) { 
          $from = $_; $from_flag = 1;
        }
      } 

      #check Endpoint as well
      $next = <$in_fh>; $next = <$in_fh>;
      for (@sparray) { 
        if ($next =~ /$_/) { 
          $to = $_; $to_flag = 1;
        } 
      }

      if ($to_flag || $from_flag) {
        while (<$in_fh>) {#2
          if (/^  slack/) {
            @tmparray = split(/\s+/); $slack = $tmparray[3];
            if ($from_flag) { 
              $from_flag = 0; 
              push @{$hashsp{$from}{$run}{from_failures}}, $slack; 
            }
            if ($to_flag) { 
              $to_flag = 0;
              push @{$hashsp{$to}{$run}{to_failures}}, $slack;   
            }
            last;#2
          }
        }
      }
      my $dbug = 1;

    }#if Startpoint
  }#while infh
}
#END MAIN LOOP

#CALC FROM/TO WNS/TNS
sub subMinAndTotal {
  if (@_ != 1) { 
    print "ERROR: &subMinAndTotal needs failures array.\n";
  } else {
    my (@failarray) = @{$_[0]}; my $min = 100000; my $total;
    for (@failarray) {
      if ($_ < $min) {$min = $_}
      $total += $_;
    }
    return (sprintf ("%.0f", $min), sprintf ("%.0f", $total));
  }
}


foreach my $spkey (sort keys %hashsp) {
  foreach my $runkey (sort keys %{$hashsp{$spkey}}) {
    if (defined $hashsp{$spkey}{$runkey}{from_failures}) {
      ($wns, $tns) = &subMinAndTotal($hashsp{$spkey}{$runkey}{from_failures});
      $hashsp{$spkey}{$runkey}{from_wnstns} = "$wns/$tns";
    } 
    if (defined $hashsp{$spkey}{$runkey}{to_failures}) {
      ($wns, $tns) = &subMinAndTotal($hashsp{$spkey}{$runkey}{to_failures});
      $hashsp{$spkey}{$runkey}{to_wnstns} = "$wns/$tns";
    }
  }
}

#DEBUG:runarray $_ position gets overwritten in the while loop in the main loop
@runarray = split(/\s+/, $runs);

#PRINT HEADER
$output = sprintf "%-50s", ("STATEPOINT");
for (sort @runarray) {
  $output .= sprintf "%+12s", ("$_");
}
$output .= sprintf "%-1s", ("\n");

#PRINT BODY
foreach my $spkey (sort keys %hashsp) {
  my $subspkey = $spkey;
  $subspkey =~ s/\\//g;
  $output .= sprintf "%-50s", ("$subspkey  (from)");
  foreach my $runkey (sort @runarray) {
    $output .= sprintf "%+12s", ($hashsp{$spkey}{$runkey}{from_wnstns});
  }
  $output .= sprintf "%-1s", ("\n");
  $output .= sprintf "%-50s", ("$subspkey  (to)");
  foreach my $runkey (sort @runarray) {
    if (defined $hashsp{$spkey}{$runkey}{to_failures}) {
      $output .= sprintf "%+12s", ($hashsp{$spkey}{$runkey}{to_wnstns});
    }
  }
  $output .= sprintf "%-1s", ("\n\n");
}
print $output;
