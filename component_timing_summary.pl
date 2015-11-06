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
#my $rptarea = "$ARGV[0]/rpts/asdf/basetup_sepair_reports";
#my $rptarea = "$ARGV[0]/rpts/asdf/basetup_sepair_reports";
my $rptarea = "$ARGV[0]/rpts/asdf/basetup_sepair_reports";

my $allsum = "$rptarea/ALL.unique.sum";
#my $resolvedlinks = "$ARGV[0]/../../../../../links/latest.links";
my $resolvedlinks = "$ARGV[0]/../../../../resolved_links.links";


my ($in_fh,$out_fh,$ID,$line,$start,$end,$tile,$IDnum,$slack,$slackidnum,$wiredelay,$budget,$port,$tilename,$count_rpt,$count_cmb,$period,$launchtime,$reqtime,$t0,$t1,$newtile,$tmp,$clock0,$clock1,$clockd);
my (@array,@arraytmp,@fan,@tran);
my (%hash,%hashtmp,%hashbgt,%hashsdc,,%hashioio);

sub getBudget {
  if (@_ != 2) { 
    print "ERROR: &getBudget needs sdc path and port.\n";
  } else { 
   
    my ($sdcfile,$port) = @_; my ($next,@array);
    open (my $sdc_fh, "gunzip -c $sdcfile |") or die "ERROR:: couldn't open file $sdcfile: $!";
    $port =~ s/\[|\]/./g;


    while (<$sdc_fh>) {
      if ( /^# .*tilepin=$port / ) {
        
        #if ( $sdcfile =~ /asdf/ && $port =~ /asdf_asdf_0.1./ ){
        #  my $flag = 1;
        #}
        
        $next = <$sdc_fh>;
        if ( $next =~ /^# Notes.*Defined in other mode.*scan/ ) { 
          $array[0] = -100; last; #SCAN only sdc flag
        } elsif ( $next =~ /^#/ && $next !~ /\(1 - / ) {
           $next = <$sdc_fh>;
        }

        if ( $next =~ /^#.*\(1 - / ) {
          @array = split(/\(budget/, $next); 
          $array[0] =~ s/^#.*\(1 - //;
          last;
        } else {
          next;
        }
      }
      
    } close $sdc_fh;
    return $array[0];
  }
}

#populate sdc hash, also has run area and publish pointers
open ($in_fh, $resolvedlinks) or die "ERROR:: couldn't open file $resolvedlinks: $!";
while (<$in_fh>) {
  @array = split(/\s+/);
  if ($array[0] =~ /^l3x$/ || $array[0] =~ /^$/ || $array[0] =~ /^#/) {
  } else {
    $array[1] =~ s/bom\.json$//; 
    $hashsdc{$array[0]}{pub} = $array[1];
    $tmp = `grep '^FLOORPLAN_SDC' $array[1]tile.params`; $tmp =~ s/^.*= //; $tmp =~ s/\\cJ.*$//; $tmp =~ s/\n//;
    $hashsdc{$array[0]}{sdc} = $tmp;
    if ($array[1] =~ /TileBuilder||run\/$/) { 
      $tmp = $array[1];
    } else {  
      $tmp = `grep '^Sources' $array[1]release.notes`;$tmp =~ s/^.*\[\'//; $tmp =~ s/\'.*$//; $tmp =~ s/\n//;
    }
    $hashsdc{$array[0]}{run} = $tmp;
  }
} close $in_fh;

#populate main hash with basic path id info
open ($in_fh, $allsum) or die "ERROR:: couldn't open file $allsum: $!";
while (<$in_fh>) {
  s/\s+//g;
  @array = split(/,/);
  $ID = $tile = $IDnum = $array[0];
  $tile =~ s/_.*$//;
  $IDnum =~ s/^.*_//;
  $start = $array[6]; $start =~ s/\d+/.*/g;
  $end   = $array[7]; $end =~ s/\d+/.*/g;
  $slack = substr($array[4], 0, -1);
  $slackidnum = "$slack$IDnum";
  $hash{$tile}{$slackidnum}{id}    = $ID;
  $hash{$tile}{$slackidnum}{slack} = $slack;
  $hash{$tile}{$slackidnum}{start} = $start;
  $hash{$tile}{$slackidnum}{end}   = $end;  
} close $in_fh;
delete $hash{"CycleTime="};

foreach my $tile_key (sort keys %hash) {
  open ($in_fh, "gunzip -c $rptarea/$tile_key.rpt.col.fmt.gz |") or die "ERROR:: couldn't open file $rptarea/$tile_key.rpt.col.fmt.gz : $!";
    foreach my $slackidnum_key (sort {$a <=> $b} keys %{$hash{$tile_key}}) {
      $slack = $hash{$tile_key}{$slackidnum_key}{slack};

      while(<$in_fh>) {

        #if ( $tile_key =~ /asdf/i &&  $slack =~ /-52\.9525/ ) { 
        #  my $flag = 1;
        #} 

        #PATH FOUND
        if(/^# .*=$slack/) {
          my $next = <$in_fh>; @array = split(/\s+/, $next);
          $hash{$tile_key}{$slackidnum_key}{prev_slack} = $array[7];
          $hash{$tile_key}{$slackidnum_key}{next_slack} = $array[10];
          $count_rpt = $count_cmb = 0;
 
          #PROCESS PATH
          while (<$in_fh>) {
            @array = split(/\s+/);
            
            if ($array[0] =~ /^\d/) {
              #FANOUT
              if ($array[3] =~ /^\d/) { push(@fan, $array[3]); }
              #TRAN
              if ($array[4] =~ /^\d/ && $array[4] !~ /^0/) { push(@tran, $array[4]); }
            }

            #GATE FOUND
            if ( $array[3] =~ /^hp/ && $array[3] !~ /msf/ ) { 
              if ( $array[3] =~ /bfx/ || $array[3] =~ /inx/ ) {
                $count_rpt += 1;
              } else { $count_cmb += 1; }
            #WIRE LENGTH FOUND
            } elsif ($array[-1] =~ /^Total=/) {
              $array[-1] =~ s/Total=//g;
              $hash{$tile_key}{$slackidnum_key}{wire_len} += $array[-1];
            #PORT FOUND
            } elsif ( $array[11] =~ /^\w+$/ && $array[12] !~ /\// && $array[12] =~ /^\(/ && $array[1] =~ /^0\.00000/) {
              $array[12] =~ s/\(|\)//g; $port = $array[12];
              $port =~ s/\d+/.*/g;
              $hash{$tile_key}{$slackidnum_key}{ports}{$port} = 1;
              $tmp = $array[3];
              if (exists $hashbgt{$tilename}) { 
                $hashioio{$tilename}++;
              }

              $hashbgt{$tilename} += &getBudget($hashsdc{$tmp}{sdc},$array[12]);
              $t1 = $array[0]; 
              $hashtmp{$tilename} += ($t1-$t0); 
              $t0 = $t1;

              $next = <$in_fh>; $next = <$in_fh>; 
              @array = split(/\s+/, $next);
              if ( $array[11] =~ /^\w+$/ && $array[12] !~ /\// && $array[12] =~ /^\(/ && $array[1] =~ /^0\.00000/ && $array[12] !~ /^\(en\)/) {
                $array[12] =~ s/\(|\)//g;
                $tmp = $array[3]; $tilename = $array[11];
                if (exists $hashbgt{$tilename}) {
                  $hashioio{$tilename}++;
                }
                $hashbgt{$tilename} += &getBudget($hashsdc{$tmp}{sdc},$array[12]);
              } elsif ( $array[3] =~ /\(out\)/ || $array[12] =~ /^\(en\)/) {
                #do nothing
              } else { 
                print "DEBUG: fix port detection\n";
                exit 0;
              }

            } elsif ( /^--/ ) {
              $next = <$in_fh>; $next =~ s/^\s+//; @array = split(/\s+/, $next);
              
              #FOUND REPORT END
              if ( $array[1] =~ /^Cell/ ) {
                $wiredelay = $array[10]; $wiredelay =~ s/\(|\)//g;
                $hash{$tile_key}{$slackidnum_key}{wire_delay} =	$wiredelay;
                $hash{$tile_key}{$slackidnum_key}{clock_skew} =	$array[14];
                $hash{$tile_key}{$slackidnum_key}{rpt} =	$count_rpt;
                $hash{$tile_key}{$slackidnum_key}{cmb} =	$count_cmb;
                
                #FIND HIGHEST FANOUT
                @arraytmp = sort { $a <=> $b } @fan;
                $hash{$tile_key}{$slackidnum_key}{fan} =	$arraytmp[-1];

                #FIND HIGHEST TRANSITION TIME                
                @arraytmp = sort { $a <=> $b } @tran;
                $hash{$tile_key}{$slackidnum_key}{tran} =	int($arraytmp[-1]);
 
                #FORMAT WIRE LENGTH
                $hash{$tile_key}{$slackidnum_key}{wire_len} = int($hash{$tile_key}{$slackidnum_key}{wire_len});

	        #ADD TILE TIMING/BUDGETS TO HASH
                my $timing_window = $hashtmp{timingwindow}; delete $hashtmp{timingwindow}; my $str = ""; my $percent;
                #if ( $slackidnum_key =~ /016666$/ ) {
                #  my $flag = 1;
                #}
                my $tmptotal = 0;
                foreach my $key (sort keys %hashtmp) {
                  my $bdgt = sprintf ("%.0f", $hashbgt{$key} * 100.0);
                  if (exists $hashioio{$key}) { 
                    $bdgt = $bdgt - 100;
                  }
                  if ($timing_window == 0.0) {
                    $percent = sprintf ("$key:T=0($bdgt)", );
                    $str = sprintf ("$str%s,", $percent);
                  } else {
                    $percent = $hashtmp{$key} / $timing_window * 100.0;
	            $percent = sprintf ("$key:%.0f($bdgt)", $percent);
                    $str = sprintf ("$str%s,", $percent);
                  }
                  $tmptotal += $bdgt;
                } 
	        $str =~ s/,$//;
                $hash{$tile_key}{$slackidnum_key}{timings} =	$str;
                $hash{$tile_key}{$slackidnum_key}{TotBdgt} = $tmptotal;
                
                undef %hashtmp;undef %hashbgt;undef %hashioio;undef @fan; undef @tran;
                last;#second while
              #FOUND WINDOW START
              } else {
                $launchtime = $array[0]; 
                $next = <$in_fh>; @array = split(/\s+/, $next);
                $t0 = $array[0]; 
                #PATH STARTS WITH PORT
                if ( $array[3] =~ /^\(in\)/ ) { 
                  $next = <$in_fh>; $next = <$in_fh>; @array = split(/\s+/, $next);
                  $array[12] =~ s/\(|\)//g; $port = $array[12];
                  $port =~ s/\d+/.*/g;
                  $hash{$tile_key}{$slackidnum_key}{ports}{$port} = 1;
                  $tmp = $array[3]; $tilename = $array[11];
                  $hashbgt{$tilename} = &getBudget($hashsdc{$tmp}{sdc},$array[12]);
                } else { 
                  $tmp = $array[11]; @array = split(/\//, $tmp);
                  $tilename = $array[0];
                  $launchtime = $t0
                }
              }

            #FOUND WINDOW END
            } elsif ( $array[3] =~ /^Arrival/ ) {
              $hashtmp{$tilename} += ($array[0]-$t0);		
              $next = <$in_fh>;$next = <$in_fh>; @array = split(/\s+/, $next);
              if ( $array[3] !~ /ext_clk/) {
                $next = <$in_fh>;$next = <$in_fh>;
              } 
              @array = split(/\s+/, $next);
              $hashtmp{timingwindow} = $array[0] - $launchtime;
            }
          }
          last;#first while
        }
      }
    }
  close $in_fh;
}

open ($out_fh, ">", "$rptarea/ALL.unique.sum.verbose") or die "ERROR:: couldn't open file $rptarea/ALL.unique.verbose: $!";
printf $out_fh "%-25s%+14s%+14s%+14s%+4s%+4s%+4s%+5s%+8s%+14s%-1s%-200s%-200s%-1s%-80s%-8s%-6s%-1s", ("ID","Prev Slack","Path Slack","Next Slack","Cmb","Bfx","Fan","Tran","NetLen","Skew"," ","Start","End"," ","tile%(budget%)","TotBdgt","Ports","\n");
close $out_fh;

open ($out_fh, ">", "$rptarea/ALL.unique.sum.mod") or die "ERROR:: couldn't open file $rptarea/ALL.unique.sum.mod: $!";
foreach my $tile_key (sort keys %hash) {
  foreach my $slackidnum_key (sort {$a <=> $b} keys %{$hash{$tile_key}}) {
    printf $out_fh "%-25s%+14s%+14s%+14s%+4s%+4s%+4s%+5s%+8s%+14s%-1s%-200s%-200s%-1s%-80s%-8s", ($hash{$tile_key}{$slackidnum_key}{id}, $hash{$tile_key}{$slackidnum_key}{prev_slack}, $hash{$tile_key}{$slackidnum_key}{slack}, $hash{$tile_key}{$slackidnum_key}{next_slack}, $hash{$tile_key}{$slackidnum_key}{cmb}, $hash{$tile_key}{$slackidnum_key}{rpt}, $hash{$tile_key}{$slackidnum_key}{fan}, $hash{$tile_key}{$slackidnum_key}{tran}, $hash{$tile_key}{$slackidnum_key}{wire_len}, $hash{$tile_key}{$slackidnum_key}{clock_skew}, " ", $hash{$tile_key}{$slackidnum_key}{start}, $hash{$tile_key}{$slackidnum_key}{end}, " ", $hash{$tile_key}{$slackidnum_key}{timings}, $hash{$tile_key}{$slackidnum_key}{TotBdgt});
    foreach my $idx (sort keys %{$hash{$tile_key}{$slackidnum_key}{ports}}) {
      printf $out_fh "$idx,";
    }
    printf $out_fh "\n";
  }
}
close $out_fh;

`cat $rptarea/ALL.unique.sum.mod | sort -nk 3 > $rptarea/ALL.unique.sum.mod.sort`;
`cat $rptarea/ALL.unique.sum.mod.sort >> $rptarea/ALL.unique.sum.verbose`;
`rm -rf $rptarea/ALL.unique.sum.mod*`;
