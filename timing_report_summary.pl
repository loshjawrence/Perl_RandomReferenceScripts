#!/tool/aticad/1.0/bin/perl
#!/usr/bin/perl -d
#use warnings;
use strict;
use POSIX;
use Data::Dumper;
if ($#ARGV < 0) { die "ERROR: No report file given\nUsage: perl timing_report_summary.pl <reportfile>\n"; }
my $dir = $ARGV[0];
my ($count,$in_fh,$infile,$out_fh,$sp,$ep,$lat,$bin_number,$state);
my $bins = 10.0;
my $scale = 1/3.0;
my (@files,@array,@hasharray);
my (%hash);
my $out_file = "$dir".".timing_summary";
#print "OUTFILE: $out_file\n";
#COMPILED REGEX'S:
my $STARTPOINT = qr/Startpoint:/;
my $ENDPOINT = qr/Endpoint:/;
my $SLACK = qr/slack \(/;
my $SEGMENT1 = qr/Path Segment: #1/;
my $SEGMENT2 = qr/Path Segment: #2/;
#match dff__ strings
my $STATEWORDS = qr/dff|lat1|lat2/;
my $FLOPNAME = qr/${STATEWORDS}__[a-zA-Z0-9_]+/;
my $GATERNAME = qr/cg__[a-zA-Z0-9_]+/;
my $TAIL = qr/_[0-9]+/;

sub compileData {
  if (@_ != 2) { 
    print "ERROR: &compileData needs and output file handle and input file name passed to it.\n";
  } else { 
    my ($p_out_fh,$p_infile) = @_; 
    my ($worst,$string,$best,%hash_spcount,%hash_epcount,%hash_latcount,%hash_spepcount);
    my $totalpaths = keys %hash;
    if (scalar(@{$hash{1}}) == 4) {
      $worst = $hash{1}[3];
    } else {
      $worst = $hash{1}[2];
    }
    if (scalar(@{$hash{$totalpaths}}) == 4) {
      $best = $hash{$totalpaths}[3];
    } else {
      $best = $hash{$totalpaths}[2];
    }
    my $range = $best - $worst;
    my $binwidth = $range/$bins;
    if ($binwidth <= 0 ) {
      print "$p_infile:\nERROR BINWIDTH = $binwidth = ($best - $worst) / $bins\n";
      return; 
    }

    #open ($p_out_fh, ">", $p_out_file) or die "ERROR:: couldn't open file $p_out_file: $!";

    my @totals;
    foreach my $key (keys %hash) {
      my $size = scalar(@{$hash{$key}});
      $bin_number = ceil(($best-$hash{$key}[$size-1])/$binwidth);
      $hash_spcount{$hash{$key}[0]}[$bin_number]++;
      $hash_epcount{$hash{$key}[$size-2]}[$bin_number]++;
      if (scalar(@{$hash{$key}}) == 4) {
        $hash_latcount{$hash{$key}[1]}[$bin_number]++;
        $hash_spepcount{"$hash{$key}[0] --> $hash{$key}[1] --> $hash{$key}[2]"}[$bin_number]++;
      } else {
        $hash_spepcount{"$hash{$key}[0] --> $hash{$key}[1]"}[$bin_number]++;
      }
      $totals[$bin_number]++;
    }
    my ($percent,$line,$top,$bot,$binlabel,@largest,$longest,$len,$longest1,$longest2,@arr);
    #Build general histogram
    $string .= "TIMING REPORT: $p_infile\nGeneral Timing Histogram:\n";
    for ($count = 0; $count < $bins; $count++) {
        $bot = sprintf "%.1f", $worst+(($count+1)*$binwidth);
        $top = sprintf "%.1f", $worst+($count*$binwidth);
        $binlabel = sprintf "%+6s < slack <= %+6s ", ($top, $bot);
 	$string .= "$binlabel" . "*" x int(($scale*$totals[$bins - $count])+0.5) . "\n";
    }

    ##Calculate biggest startpoint contributors for each bin
    $string .= "\nLargest STARTPOINT contributors for each bin:\n";
    foreach my $key (keys %hash_spcount) {
      for ($count = $bins; $count > 0; $count--) {
        if ($hash_spcount{$key}[$count] > $largest[$count][1]) {
          $len = length($key);
          if ($len > $longest) { $longest = $len; }
          $largest[$count][0] = $key;#store flop to [0]
          $largest[$count][1] =  $hash_spcount{$key}[$count];#store count in bin to [1]
        }
      }
    }
    for ($count = 0; $count < $bins; $count++) {
        $bot = sprintf "%.1f", $worst+(($count+1)*$binwidth);
        $top = sprintf "%.1f", $worst+($count*$binwidth);
        $binlabel = sprintf "%+6s < slack <= %+6s ", ($top, $bot);
        if ($totals[$bins-$count] == 0) {
          $string .= "$binlabel STARTPOINT: BIN EMPTY\n";
        } else {
          $percent = sprintf "%.1f", (($largest[$bins-$count][1]*100.0)/$totals[$bins-$count]);#store percentage of bin to [1]
 	  $line = sprintf "%s %s %-${longest}s %+6s", ($binlabel, "STARTPOINT:", $largest[$bins - $count][0], "$percent\%\n");
          $string .= $line;
        }
    }
    
    ##Calculate biggest latch contributors for each bin
    $string .= "\nLargest LATCH contributors for each bin:\n";
    undef @largest;
    $len = 0;
    $longest = 0;
    foreach my $key (keys %hash_latcount) {
      for ($count = $bins; $count > 0; $count--) {
        if ($hash_latcount{$key}[$count] > $largest[$count][1]) {
          $len = length($key);
          if ($len > $longest) { $longest = $len; }
          $largest[$count][0] = $key;#store flop to [0]
          $largest[$count][1] =  $hash_latcount{$key}[$count];#store count in bin to [1]
        }
      }
    }
    for ($count = 0; $count < $bins; $count++) {
        $bot = sprintf "%.1f", $worst+(($count+1)*$binwidth);
        $top = sprintf "%.1f", $worst+($count*$binwidth);
        $binlabel = sprintf "%+6s < slack <= %+6s ", ($top, $bot);
        if ($totals[$bins-$count] == 0) {
          $string .= "$binlabel LATCH: BIN EMPTY\n";
        } else {
          $percent = sprintf "%.1f", (($largest[$bins-$count][1]*100.0)/$totals[$bins-$count]);#store percentage of bin to [1]
          $line = sprintf "%s %s %-${longest}s %+6s", ($binlabel, "LATCH:", $largest[$bins - $count][0], "$percent\%\n");
          $string .= $line;
        }
    }

    ##Calculate biggest endpoint contributors for each bin
    $string .= "\nLargest ENDPOINT contributors for each bin:\n";
    undef @largest;
    $len = 0;
    $longest = 0;
    foreach my $key (keys %hash_epcount) {
      for ($count = $bins; $count > 0; $count--) {
         if ($hash_epcount{$key}[$count] > $largest[$count][1]) {
           $len = length($key);
           if ($len > $longest) { $longest = $len; }
           $largest[$count][0] = $key;#store flop to [0]
           $largest[$count][1] = $hash_epcount{$key}[$count];#store count in bin to [1]
         }
      }
    }
    for ($count = 0; $count < $bins; $count++) {
      $bot = sprintf "%.1f", $worst+(($count+1)*$binwidth);
      $top = sprintf "%.1f", $worst+($count*$binwidth);
      $binlabel = sprintf "%+6s < slack <= %+6s ", ($top, $bot);
      if ($totals[$bins-$count] == 0) {
        $string .= "$binlabel ENDPOINT: BIN EMPTY\n";
      } else {
        $percent = sprintf "%.1f", (($largest[$bins-$count][1]*100.0)/$totals[$bins-$count]);#store percentage of bin to [1]
        $line = sprintf "%s %s %-${longest}s %+6s", ($binlabel, "ENDPOINT:", $largest[$bins - $count][0], "$percent\%\n");
        $string .= $line;
      }
    }
    
    ##Calculate biggest startpoint/endpoint combo contributors for each bin
    $string .= "\nLargest STARTPOINT/ENDPOINT contributors for each bin:\n";
    undef @largest;
    $longest = 0;
    foreach my $key (keys %hash_spepcount) {
      for ($count = $bins; $count > 0; $count--) {
        if ($hash_spepcount{$key}[$count] > $largest[$count][1]) {
          $largest[$count][0] = $key;#store flop to [0]
          $largest[$count][1] = $hash_spepcount{$key}[$count];#store count in bin to [1]
          
          @arr = split(" --> ", $largest[$count][0]);
          $len = length($arr[0]);
          if ($len > $longest) { $longest = $len; }
          $len = length($arr[1]);
          if ($len > $longest1) { $longest1 = $len; }
          $len = length($arr[2]);
          if ($len > $longest2) { $longest2 = $len; }
        }
      }
    }
    for ($count = 0; $count < $bins; $count++) {
        $bot = sprintf "%.1f", $worst+(($count+1)*$binwidth);
        $top = sprintf "%.1f", $worst+($count*$binwidth);
        $binlabel = sprintf "%+6s < slack <= %+6s ", ($top, $bot);
        if ($totals[$bins-$count] == 0) {
          $string .= "$binlabel BIN EMPTY\n"
        } else {
          $percent = sprintf "%.1f", (($largest[$bins-$count][1]*100.0)/$totals[$bins-$count]);#store percentage of bin to [1]
          @arr = split(" --> ", $largest[$bins - $count][0]);
          $line = sprintf "%s %-${longest}s --> %-${longest1}s --> %-${longest2}s %+6s", ($binlabel, $arr[0], $arr[1], $arr[2], "$percent\%\n");
          $string .= $line;
        }
    }
    $string .= "\n\n\n";
    print $string
    #close ($p_out_fh);
    #end else
  }
  #end sub
}

if ($dir =~/max\.rpt\.gz/) { @files = glob("$dir"); 
} else { @files = glob("$dir*max.rpt.gz"); }

#open ($out_fh, ">", $out_file) or die "ERROR:: couldn't open file $out_file: $!";
foreach $infile (@files) {
  open ($in_fh, "gunzip -c $infile |") or die "ERROR:: couldn't open file $infile: $!";
  $count = $state = 0;
  undef %hash;
  while (<$in_fh>) {
    if(/$STARTPOINT/) {
      $count++ if $state == 0;
      s/^\s+//;
      @array = split(/\s+/);
      if ($state != 2) {
        if ($array[1] =~/($FLOPNAME)/) { #flop
          $sp = $1 if $array[1] =~/($FLOPNAME)/;
          $sp =~s/\d/\*/g;
        } elsif ($array[1] =~/($GATERNAME)/) { #gate
          $sp = $1 if $array[1] =~/($GATERNAME)/;
          $sp =~s/\d/\*/g;
        } else { #port
          $sp = $array[1];
          $sp =~s/\[\d+\]/\[\*\]/g;
        }
      }   
    } elsif (/$ENDPOINT/) {
      s/^\s+//;
      @array = split(/\s+/);
      if ($array[1] =~/($FLOPNAME)/) {#flop
        if ($state != 1) { 
          $ep = $1 if $array[1] =~/($FLOPNAME)/;
          $ep =~s/\d/\*/g;
        } else {
          $lat = $1 if $array[1] =~/($FLOPNAME)/;
          $lat =~s/\d/\*/g;
        }
      } elsif ($array[1] =~/($GATERNAME)/) {#gate
        if ($state != 1) {
          $ep = $1 if $array[1] =~/($GATERNAME)/;
          $ep =~s/\d/\*/g;
        } else {
          $lat = $1 if $array[1] =~/($GATERNAME)/;
          $lat =~s/\d/\*/g;
        } 
      } else { #port
        $ep = $array[1] if $state == 0;
        $ep =~s/\[\d+\]/\[\*\]/g;
      }
    } elsif (/$SLACK/) {
      s/^\s+//;
      @array = split(/\s+/);
      if ($state == 0) { 
        @hasharray = ($sp,$ep,$array[2]);
        $hash{$count} = [@hasharray];
      } elsif ($state == 2) {
        @hasharray = ($sp,$lat,$ep,$array[2]);
        $hash{$count} = [@hasharray];
        $state = 0;
      }
    } elsif (/$SEGMENT1/) {
      $state=1;
    } elsif (/$SEGMENT2/) {
      $state=2;
    }
    
  #end while in_f
  }
  close $in_fh;
  &compileData($out_fh,$infile);
}
close ($out_fh);
exit 0;
