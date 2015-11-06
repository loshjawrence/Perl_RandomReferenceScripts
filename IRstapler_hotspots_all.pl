#!usr/bin/perl 
use warnings;
use strict;
#Takes as input a .inst file from asdf DB from a non-staple run and calculates regions of the tile that need to be stapled
#Run from the base dir of the branch you plan on using hotspot stapling

my $PrintFlag = grep(/Print/, @ARGV);
my $SkipMacros = grep(/SkipMacros/, @ARGV);
my $InstFile;
my $hotspot_fh;
my $runset_fh;
my $cmd_fh;
my $cmdMOD_fh;
if ($#ARGV < 0) {  die "ERROR: No inst file given\nUsage: CalculateTileStats.pl <InstFile>\n"; }
open ($InstFile, "gunzip -dc $ARGV[0] |") or die "Cannot find $ARGV[0]";

my $TileName = $ARGV[0];
$TileName =~ s/\.inst//;
$TileName =~ s/.*\///;

my $path_asdfCMD = "cmds/Icasdf.cmd";
my $path_asdfMOD_CMD = "cmds/Icasdf_MOD.cmd";
my $path_runset_template = "/home/jlawrenc/staple/asdf_asdf_staple_separate.rs";
my $runset_hotspot = "asdf_staple_HOTSPOT_separate.rs";
my $runset_template = "asdf_staple_separate.rs";
my $path_pwd = "$ENV{PWD}";
my $runset_tcl = "set runset $path_pwd/$runset_hotspot\n";
my %gridhashVDD; #hash , keys: grid coords(lower left), values: polygon coords(lower left and upper right)
my %gridhashVSS;
my %gridhashVDDtoVSS;


#for experiments, change these before you run the script (+asdf-asdf)(create a window that will always capture the same number of pairs)
#asdf distance of asdf pairs of asdf Vdd/Vss rails(set at asdf for consistant asdf pairs)
#asdf distance of asdf pairs of asf Vdd/Vss rails(set at asdf for consistant asdf pairs)
#asdf distance of asdf pairs of asdf Vdd/Vss rails(set at asdf for consistant asdf pairs)
my $topVpwrwidth = asdf; # pwr rail width of top vertical metal that gets stapled (asdf)
my $topVMspacing = asdf; #vdd-vss rail spacing for top vertical metal that gets stapled (asdf)
my $topVstapleXdim = asdf; # x dimension of top metal staple (asdf)
my $topHpwrwidth = asdf; # pwr rail width of top horizontal metal that gets stapled (asdf)
my $topHMspacing = asdf; # vdd-vss rail spacing for top horizontal metal that gets stapled (asdf)
my $topHstapleYdim = asdf; # x dimension of top metal staple (asdf)

my $railpairs = asdf; # number of rail pairs

# your tile is broken up into little $gridsizeX by $gridsizeY boxes (um)

my $gridsizeX = (2*$railpairs*$topVMspacing) - ($topVstapleXdim + 0.001); 
my $gridsizeY = (2*$railpairs*$topHMspacing) - ($topHstapleYdim + 0.001);
my $thesholdVDD = asdf; # if VDD drop is >= $thresholdVDD the box is flagged for VDD stapling (volts)
my $thesholdVSS = sdf; # if VSS bounce is >= $thresholdVSS the box is flagged for VSS stapling (volts)
my $thesholdVDDtoVSS =  asdf;# if VDD-VSS bounce is >= $thresholdVDDtoVSS the box is flagged for VDD and VSS stapling (volts)
my $gridxVDD = 0; # lower left x coord of grid box that gets flagged for a VDD drop violation
my $gridyVDD = 0; # lower left y coord of grid box that gets flagged for a VDD drop violation
my $gridxVSS = 0; # lower left y coord of grid box that gets flagged for a VSS bounce violation
my $gridyVSS = 0; # lower left y coord of grid box that gets flagged for a VSS bounce violation
my $gridxVDDtoVSS = 0; # lower left y coord of grid box that gets flagged for a VDDtoVSS drop violation
my $gridyVDDtoVSS = 0; # lower left y coord of grid box that gets flagged for a VDDtoVSS drop violation
my $gridcoordVDD = "";# something like "asdf,asdf" (key in the gridhash)
my $gridcoordVSS = "";
my $gridcoordVDDtoVSS = "";
my $polycoordVDD = "";# something like "{{asdf, asdf}, {asdf, asdf}}" (value in the gridhash)
my $polycoordVSS = "";
my $polycoordVDDtoVSS = "";
my $c;
my @Words;
my $polyx;
my $polyy;
my $hashsize;


my $include_surrounding_regions = 1; #turn on to include surrounding boxes of flagged boxes

while (<$InstFile>) {
  my $Line = $_;
  next if ($Line =~ /^#/);# skip to next line if the current line is a comment
  next if ($Line =~ /asdf|asdf/); # skip filler and cap instances
  @Words=split(" ", $Line);
  if ($SkipMacros) {
    next if ($Line =~ /asdf$/);
    if ($TileName =~ /asdf/) {
      #Skip broken power grid in lower right.
      #REMOVE POST asdfasdf
      next if ($Words[8] =~ /sdf/);
      $Words[6] =~ s/,//;
      $Words[7] =~ s/\)//;
      if (($Words[6] > 695) && ($Words[7] < 50)) { next; }
    }
  }
  if ($#Words>=2) { # $# is the index of the last item in the array
    if($Words[1] >= $thesholdVDD) { #temporary ||
      $Words[6] =~ s/,//;
      $Words[7] =~ s/\)//;
      #flagged box
      $gridxVDD = int($Words[6] / $gridsizeX);# should chop off fraction part
      $gridyVDD = int($Words[7] / $gridsizeY);
      $gridcoordVDD = sprintf("%s, %s", $gridxVDD , $gridyVDD); #assign a string coordinate
      if(!$include_surrounding_regions){
        if(!$gridhashVDD{$gridcoordVDD}) { # if doesn't exist, assign polygon
          $polyx = sprintf "%.3f", ($gridxVDD*$gridsizeX);
          $polyy = sprintf "%.3f", ($gridyVDD*$gridsizeY);
          $polycoordVDD = sprintf("{{%s, %s}, {%s, %s}}", $polyx, $polyy, sprintf("%.3f", $polyx+$gridsizeX), sprintf("%.3f", $polyy+$gridsizeY)); #string is used for the stapler runset script
          $gridhashVDD{$gridcoordVDD} = $polycoordVDD;
        }
      } else {
        if(!$gridhashVDD{$gridcoordVDD}) { # if doesn't exist, assign polygon
          $polyx = sprintf "%.3f", (($gridxVDD-1)*$gridsizeX);
          $polyy = sprintf "%.3f", (($gridyVDD-1)*$gridsizeY);
          $polycoordVDD = sprintf("{{%s, %s}, {%s, %s}}", $polyx, $polyy, sprintf("%.3f", $polyx+(3*$gridsizeX)), sprintf("%.3f", $polyy+(3*$gridsizeY)));
          $gridhashVDD{$gridcoordVDD} = $polycoordVDD;
        }
      }
    }
    if($Words[2] >= $thesholdVSS) { 
      $Words[6] =~ s/,//;
      $Words[7] =~ s/\)//;
      $gridxVSS = int($Words[6] / $gridsizeX);# should chop off fraction part
      $gridyVSS = int($Words[7] / $gridsizeY);
      $gridcoordVSS = sprintf("%s, %s", $gridxVSS, $gridyVSS);
      if(!$include_surrounding_regions) {
        if(!$gridhashVSS{$gridcoordVSS}) { # if doesn't exist, assign polygon
          $polyx = sprintf "%.3f", ($gridxVSS*$gridsizeX);
          $polyy = sprintf "%.3f", ($gridyVSS*$gridsizeY);
          $polycoordVSS = sprintf("{{%s, %s}, {%s, %s}}", $polyx, $polyy, sprintf("%.3f", $polyx+$gridsizeX), sprintf("%.3f", $polyy+$gridsizeY));
          $gridhashVSS{$gridcoordVSS} = $polycoordVSS;
        }
      } else {
        if(!$gridhashVSS{$gridcoordVSS}) { # if doesn't exist, assign polygon
          $polyx = sprintf "%.3f", (($gridxVSS-1)*$gridsizeX);
          $polyy = sprintf "%.3f", (($gridyVSS-1)*$gridsizeY);
          $polycoordVSS = sprintf("{{%s, %s}, {%s, %s}}", $polyx, $polyy, sprintf("%.3f", $polyx+(3*$gridsizeX)), sprintf("%.3f", $polyy+(3*$gridsizeY)));
          $gridhashVSS{$gridcoordVSS} = $polycoordVSS;
        }
      }
    }
    if($Words[1]+$Words[2] >= $thesholdVDDtoVSS) { 
      $Words[6] =~ s/,//;
      $Words[7] =~ s/\)//;
      $gridxVDDtoVSS = int($Words[6] / $gridsizeX);# should chop off fraction part
      $gridyVDDtoVSS = int($Words[7] / $gridsizeY);
      $gridcoordVDDtoVSS = sprintf("%s, %s", $gridxVDDtoVSS, $gridyVDDtoVSS);
      if(!$include_surrounding_regions) {
        if(!$gridhashVDDtoVSS{$gridcoordVDDtoVSS}) { # if doesn't exist, assign polygon
          $polyx = sprintf "%.3f", ($gridxVDDtoVSS*$gridsizeX);
          $polyy = sprintf "%.3f", ($gridyVDDtoVSS*$gridsizeY);
          $polycoordVDDtoVSS = sprintf("{{%s, %s}, {%s, %s}}", $polyx, $polyy, sprintf("%.3f", $polyx+$gridsizeX), sprintf("%.3f", $polyy+$gridsizeY));
          $gridhashVDDtoVSS{$gridcoordVDDtoVSS} = $polycoordVDDtoVSS;
        }
      } else {
        if(!$gridhashVDDtoVSS{$gridcoordVDDtoVSS}) { # if doesn't exist, assign polygon
          $polyx = sprintf "%.3f", (($gridxVDDtoVSS-1)*$gridsizeX);
          $polyy = sprintf "%.3f", (($gridyVDDtoVSS-1)*$gridsizeY);
          $polycoordVDDtoVSS = sprintf("{{%s, %s}, {%s, %s}}", $polyx, $polyy, sprintf("%.3f", $polyx+(3*$gridsizeX)), sprintf("%.3f", $polyy+(3*$gridsizeY)));
          $gridhashVDDtoVSS{$gridcoordVDDtoVSS} = $polycoordVDDtoVSS;
        }
      }
    }
  }
}
close $InstFile;
#copy runset_template(stapler code) to pwd, insert poly coords, modify Icasdf.cmd to use this runset

system(sprintf"cp %s %s", ($path_runset_template, $path_pwd));
open($runset_fh, '<', $runset_template) or die "ERROR:: couldn't open file asdf_staple_beta.rs: $!";
open($hotspot_fh, '>', $runset_hotspot) or die "ERROR:: couldn't open file asdf_staple_HOTSPOT.rs: $!";
while(<$runset_fh>){
  chomp;
  if(/^\/\/HOTSPOT POLYGONS/) {# find insert point
    $hashsize = keys %gridhashVDD;
    $c = 1;
    if($hashsize > 0) {
      printf $hotspot_fh "//HOTSPOT POLYGONS\nhotspots_VDD = polygons({"; 
      foreach my $key (sort keys %gridhashVDD){
        if($c != $hashsize){ 
          printf $hotspot_fh "\n\t%s,", ($gridhashVDD{$key});
        } else { #last one, no comma
          printf $hotspot_fh "\n\t%s", ($gridhashVDD{$key});
        }
        $c++;
      }
      printf $hotspot_fh "\n});";
    } else { #create a 0x0 polygon, i.e. no staples
      printf $hotspot_fh "//HOTSPOT POLYGONS\nhotspots_VDD = polygons({";
      printf $hotspot_fh "\n{{0, 0}, {0, 0}}";
      printf $hotspot_fh "\n});";
    }
    
    $hashsize = keys %gridhashVSS;
    $c = 1;
    if($hashsize > 0) {
      printf $hotspot_fh "//HOTSPOT POLYGONS\nhotspots_VSS = polygons({"; 
      $hashsize = keys %gridhashVSS;
      $c = 1;
      foreach my $key (sort keys %gridhashVSS){
        if($c != $hashsize){ 
          printf $hotspot_fh "\n\t%s,", ($gridhashVSS{$key});
        } else { #last one, no comma
          printf $hotspot_fh "\n\t%s", ($gridhashVSS{$key});
        }
        $c++;
      }
      printf $hotspot_fh "\n});";
    } else { #create a 0x0 polygon, i.e. no staples
      printf $hotspot_fh "//HOTSPOT POLYGONS\nhotspots_VSS = polygons({";
      printf $hotspot_fh "\n{{0, 0}, {0, 0}}";
      printf $hotspot_fh "\n});";
    }

    $hashsize = keys %gridhashVDDtoVSS;
    $c = 1;
    if($hashsize > 0) {
      printf $hotspot_fh "//HOTSPOT POLYGONS\nhotspots_VDDtoVSS = polygons({"; 
      $hashsize = keys %gridhashVDDtoVSS;
      $c = 1;
      foreach my $key (sort keys %gridhashVDDtoVSS){
        if($c != $hashsize){ 
          printf $hotspot_fh "\n\t%s,", ($gridhashVDDtoVSS{$key});
        } else { #last one, no comma
          printf $hotspot_fh "\n\t%s", ($gridhashVDDtoVSS{$key});
        }
        $c++;
      }
      printf $hotspot_fh "\n});";
    } else { #create a 0x0 polygon, i.e. no staples
      printf $hotspot_fh "//HOTSPOT POLYGONS\nhotspots_VDDtoVSS = polygons({";
      printf $hotspot_fh "\n{{0, 0}, {0, 0}}";
      printf $hotspot_fh "\n});";
    }

    printf $hotspot_fh "\n//do interacting with all via collections and the hotspots polygon:
new_ma = interacting(new_asdf, hotspots_VDD, include_touch=ALL);
new_mb = interacting(new_asdf, hotspots_VDD, include_touch=ALL);
new_mc = interacting(new_asdf, hotspots_VDD, include_touch=ALL);
hnew_va_VDD = interacting(hnew_asdf_VDD, hotspots_VDD, include_touch=ALL);
hnew_vb_VDD = interacting(hnew_asdf_VDD, hotspots_VDD, include_touch=ALL);
hnew_vc_VDD = or(interacting(hnew_asdf_VDD, hotspots_VDD, include_touch=ALL), interacting(hnew_asdf_VDD, new_asdf, include_touch=ALL));
hnew_vd_VDD = or(interacting(hnew_asdf_VDD, hotspots_VDD, include_touch=ALL), interacting(hnew_asdf_VDD, new_asdf, include_touch=ALL));
hnew_va_VDD = interacting(hnew_asdf_VDD, hotspots_VDD, include_touch=ALL);
hnew_vb_VDD = interacting(hnew_asdf_VDD, hotspots_VDD, include_touch=ALL);
hnew_vc_VDD = interacting(hnew_asdf_VDD, hotspots_VDD, include_touch=ALL);
vnew_vd_VDD = interacting(vnew_asdf_VDD, hotspots_VDD, include_touch=ALL);
vnew_va_VDD = interacting(vnew_asdf_VDD, hotspots_VDD, include_touch=ALL);
vnew_vb_VDD = interacting(vnew_asdf_VDD, hotspots_VDD, include_touch=ALL);
vnew_vc_VDD = or(interacting(vnew_asdf_VDD, hotspots_VDD, include_touch=ALL), interacting(vnew_asdf_VDD, new_asdf, include_touch=ALL));
vnew_vd_VDD = or(interacting(vnew_asdf_VDD, hotspots_VDD, include_touch=ALL), interacting(vnew_asdf_VDD, new_asdf, include_touch=ALL));
vnew_va_VDD = or(interacting(vnew_asdf_VDD, hotspots_VDD, include_touch=ALL), interacting(vnew_asdf_VDD, new_asdf, include_touch=ALL));
vnew_vb_VDD = or(interacting(vnew_asdf_VDD, hotspots_VDD, include_touch=ALL), interacting(vnew_asdf_VDD, new_asdf, include_touch=ALL));

hnew_asdf_VSS = interacting(hnew_asdf_VSS, hotspots_VSS, include_touch=ALL);
hnew_asdf_VSS = interacting(hnew_asdf_VSS, hotspots_VSS, include_touch=ALL);
hnew_asdf_VSS = interacting(hnew_asdf_VSS, hotspots_VSS, include_touch=ALL);
hnew_asdf_VSS = interacting(hnew_asdf_VSS, hotspots_VSS, include_touch=ALL);
hnew_asdf_VSS = interacting(hnew_asdf_VSS, hotspots_VSS, include_touch=ALL);
hnew_asdf_VSS = interacting(hnew_asdf_VSS, hotspots_VSS, include_touch=ALL);
hnew_asdf_VSS = interacting(hnew_asdf_VSS, hotspots_VSS, include_touch=ALL);
vnew_asdf_VSS = interacting(vnew_asdf_VSS, hotspots_VSS, include_touch=ALL);
vnew_asdf_VSS = interacting(vnew_asdf_VSS, hotspots_VSS, include_touch=ALL);
vnew_asdf_VSS = interacting(vnew_asdf_VSS, hotspots_VSS, include_touch=ALL);
vnew_asdf_VSS = interacting(vnew_asdf_VSS, hotspots_VSS, include_touch=ALL);
vnew_asdf_VSS = interacting(vnew_asdf_VSS, hotspots_VSS, include_touch=ALL);
vnew_asdf_VSS = interacting(vnew_asdf_VSS, hotspots_VSS, include_touch=ALL);
vnew_asdf_VSS = interacting(vnew_asdf_VSS, hotspots_VSS, include_touch=ALL);

//VDDtoVSS drop violations
hotspots_VDDtoVSS = or(not(hotspots_VDDtoVSS, hotspots_VDD), not(hotspots_VDDtoVSS, hotspots_VSS));
new_asdf = or( new_asdf, interacting(new_asdf, hotspots_VDDtoVSS, include_touch=ALL));
new_asdf = or( new_asdf, interacting(new_asdf, hotspots_VDDtoVSS, include_touch=ALL));
new_asdf = or( new_asdf, interacting(new_asdf, hotspots_VDDtoVSS, include_touch=ALL));
hnew_asdf_VDD = or( hnew_asdf_VDD, interacting(hnew_asdf_VDD, hotspots_VDDtoVSS, include_touch=ALL));
hnew_asdf_VDD = or( hnew_asdf_VDD, interacting(hnew_asdf_VDD, hotspots_VDDtoVSS, include_touch=ALL));
hnew_asdf_VDD = or( hnew_asdf_VDD, or(interacting(hnew_asdf_VDD, hotspots_VDDtoVSS, include_touch=ALL), interacting(hnew_asdf_VDD, new_asdf, include_touch=ALL)));
hnew_asdf_VDD = or( hnew_asdf_VDD, or(interacting(hnew_asdf_VDD, hotspots_VDDtoVSS, include_touch=ALL), interacting(hnew_asdf_VDD, new_asdf, include_touch=ALL)));
hnew_asdf_VDD = or( hnew_asdf_VDD, interacting(hnew_asdf_VDD, hotspots_VDDtoVSS, include_touch=ALL));
hnew_asdf_VDD = or( hnew_asdf_VDD, interacting(hnew_asdf_VDD, hotspots_VDDtoVSS, include_touch=ALL));
hnew_asdf_VDD = or( hnew_asdf_VDD, interacting(hnew_asdf_VDD, hotspots_VDDtoVSS, include_touch=ALL));
vnew_asdf_VDD = or( vnew_asdf_VDD, interacting(vnew_asdf_VDD, hotspots_VDDtoVSS, include_touch=ALL));
vnew_asdf_VDD = or( vnew_asdf_VDD, interacting(vnew_asdf_VDD, hotspots_VDDtoVSS, include_touch=ALL));
vnew_asdf_VDD = or( vnew_asdf_VDD, interacting(vnew_asdf_VDD, hotspots_VDDtoVSS, include_touch=ALL));
vnew_asdf_VDD = or( vnew_asdf_VDD, or(interacting(vnew_asdf_VDD, hotspots_VDDtoVSS, include_touch=ALL), interacting(vnew_asdf_VDD, new_asdf, include_touch=ALL)));
vnew_asdf_VDD = or( vnew_asdf_VDD, or(interacting(vnew_asdf_VDD, hotspots_VDDtoVSS, include_touch=ALL), interacting(vnew_asdf_VDD, new_asdf, include_touch=ALL)));
vnew_asdf_VDD = or( vnew_asdf_VDD, or(interacting(vnew_asdf_VDD, hotspots_VDDtoVSS, include_touch=ALL), interacting(vnew_asdf_VDD, new_asdf, include_touch=ALL)));
vnew_asdf_VDD = or( vnew_asdf_VDD, or(interacting(vnew_asdf_VDD, hotspots_VDDtoVSS, include_touch=ALL), interacting(vnew_asdf_VDD, new_asdf, include_touch=ALL)));

hnew_asdf_VSS = or( hnew_asdf_VSS, interacting(hnew_asdf_VSS, hotspots_VDDtoVSS, include_touch=ALL));
hnew_asdf_VSS = or( hnew_asdf_VSS, interacting(hnew_asdf_VSS, hotspots_VDDtoVSS, include_touch=ALL));
hnew_asdf_VSS = or( hnew_asdf_VSS, interacting(hnew_asdf_VSS, hotspots_VDDtoVSS, include_touch=ALL));
hnew_asdf_VSS = or( hnew_asdf_VSS, interacting(hnew_asdf_VSS, hotspots_VDDtoVSS, include_touch=ALL));
hnew_asdf_VSS = or( hnew_asdf_VSS, interacting(hnew_asdf_VSS, hotspots_VDDtoVSS, include_touch=ALL));
hnew_asdf_VSS = or( hnew_asdf_VSS, interacting(hnew_asdf_VSS, hotspots_VDDtoVSS, include_touch=ALL));
hnew_asdf_VSS = or( hnew_asdf_VSS, interacting(hnew_asdf_VSS, hotspots_VDDtoVSS, include_touch=ALL));
vnew_asdf_VSS = or( vnew_asdf_VSS, interacting(vnew_asdf_VSS, hotspots_VDDtoVSS, include_touch=ALL));
vnew_asdf_VSS = or( vnew_asdf_VSS, interacting(vnew_asdf_VSS, hotspots_VDDtoVSS, include_touch=ALL));
vnew_asdf_VSS = or( vnew_asdf_VSS, interacting(vnew_asdf_VSS, hotspots_VDDtoVSS, include_touch=ALL));
vnew_asdf_VSS = or( vnew_asdf_VSS, interacting(vnew_asdf_VSS, hotspots_VDDtoVSS, include_touch=ALL));
vnew_asdf_VSS = or( vnew_asdf_VSS, interacting(vnew_asdf_VSS, hotspots_VDDtoVSS, include_touch=ALL));
vnew_asdf_VSS = or( vnew_asdf_VSS, interacting(vnew_asdf_VSS, hotspots_VDDtoVSS, include_touch=ALL));
vnew_asdf_VSS = or( vnew_asdf_VSS, interacting(vnew_asdf_VSS, hotspots_VDDtoVSS, include_touch=ALL));

";
  next;
  }
  printf $hotspot_fh "%s\n", ($_);
}
close $runset_fh;
close $hotspot_fh;

open($cmd_fh, '<', $path_asdfCMD) or die "ERROR:: couldn't open file cmds/Icasdf.cmd: $!";
open($cmdMOD_fh, '>', $path_asdfMOD_CMD) or die "ERROR:: couldn't open file cmds/Icasdf_MOD.cmd: $!";
while(<$cmd_fh>){
  chomp;
  if(/^set runset/){
    printf $cmdMOD_fh "%s\n", ($runset_tcl); #replace entire line with runset file location
    next;
  }
  printf $cmdMOD_fh "%s\n", ($_);
}
close $cmd_fh;
close $cmdMOD_fh;
system(sprintf"cp %s %s", ($path_asdfCMD, "$path_asdfCMD.bak"));
system(sprintf"cp %s %s", ($path_asdfMOD_CMD, $path_asdfCMD));
