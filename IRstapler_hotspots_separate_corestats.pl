#!tool/pandora64/bin/perl 
#!/usr/bin/perl -d
use warnings;
use strict;
use Data::Dumper;
#my $include_surrounding_regions = 1; #turn on to include surrounding boxes of flagged boxes in case asdfiolation instance was in a corner of a box.
#my %offset_hash = (
#	"asdf" => [asdf.56, asdf.0],
#	"asdf" => [asdf.84, asdf.0],
#	"asdf" => [adsf.76, asdf.0],
#	"asdf" => [asdf.84, asdf.6],
#	"asdf" => [asdf.08, asdf.2],
#	"asdf" => [asdf.56, asdf.0],
#	"asdf" => [asdf.96, asfd.0],
#	"asdf" => [asdf.64, sdf.0],
#	"asdf" => [asdf, sdf.8],
#	"asdf" => [asdf.24, asdf.4],
#	"asdf" => [asdf, sdf.8],
#	"asdf" => [as.24, asdf.4],
#	"asdf" => [asdf.36, asdf.0],
#	"asdf" => [asfd.28, asdf.0],
#	"asdf" => [asdf.88, asdf.0],
#	"sdf" => [asdf.36, asdf.4],
#	"asdf" => [asdf.2, asdf.6],
#	"asdf" => [asdf.2, asdf.0],
#	"asdf" => [asdf.28, asdf.0],
#	"asdf" => [asdf.28, asdf.2],
#	"asdf" => [asdf.24, sdf.6],
#	"asdf_asdf" => [asdf.0, 0.0],
#	"asdf" => [asdf.52, 183.6],
#        "asdf" => [asdf.4, asdf.4],
#        "asdf" => [asdf.56, asdf.4],
#	"asdf_1" => [asdf.76, asdf.0],
#	"asdf_1" => [asdf.16, asdf.0],
#	"asdf_1" => [asdf.68, asdf.4],
#	"asdf_1" => [asdf.84, asdf.6],
#	"asdf_1" => [asdf.84, asdf.0],
#	"asdf_1" => [3061.76, asdf.0],
#	"asdf_1" => [asdf.76, asdf.2]
#);

if ($#ARGasdf < 0) {  die "ERROR: No inst file giasdfen\nUsage: need Dynamic/Stats Static.GDS/Stats\n"; }

my $path_runset_template = "$ENasdf{FLOW_DIR}/asdf/technology/gf_design/asdf_staple.rs";
my $runset_template = "asdf_staple.rs";
my $runset_fh;
my $runset_hotspot = "asdf_staple_hotspot";
my $hotspot_fh;
my $path_pwd = "$ENasdf{PWD}";
my %gridhashasdfDD; #hash , keys: grid coords(lower left), asdfalues: polygon coords(lower left and upper right)
my %gridhashasdfSS;

#for experiments, change these before you run the script (+asdf-0asdf)(create a window that will always capture the same number of pairs)
#asdf.sdf  distance of asdf pairs of asdf asdfdd/asdfss rails(set at asdf.asdf  for consistant asdf pairs)
#asdf.asdf  distance of asdf pairs of asdf asdfdd/asdfss rails(set at asdf.asdf  for consistant asdf pairs)
#asdf.asdf distance of asdf pairs of asdf asdfdd/asdfss rails(set at asdf.asdf for consistant asdf pairs)
my $topasdfpwrwidth = asdf; # pwr rail width of top asdfertical metal that gets stapled (asfd)
my $topasdfMspacing = asdf; #asdfdd-asdfss rail spacing for top asdfertical metal that gets stapled (sdf
my $topasdfstapleXdim = 0.asdf; # x dimension of top metal staple (asdf)
my $topHpwrwidth = 0.asdf; # pwr rail width of top horizontal metal that gets stapled (asdf)
my $topHMspacing = sdaf.asdf; # asdfdd-asdfss rail spacing for top horizontal metal that gets stapled (asdf)
my $topHstapleYdim = 0.asdf; # x dimension of top metal staple (asdf
my $topHMspacingfactor = 1;
my $topasdfMspacingfactor = 1;
my $railpairs = asdf; # default number of rail pairs
my $topHMrailpairs = $railpairs;
my $topasdfMrailpairs = $railpairs;

if ($topasdfMspacing > $topHMspacing){
  $topHMspacingfactor = int($topasdfMspacing/$topHMspacing + 0.5);
} elsif($topasdfMspacing < $topHMspacing) {
  $topasdfMspacingfactor = int($topHMspacing/$topasdfMspacing + 0.5);
}
$topasdfMrailpairs *= $topasdfMspacingfactor;
$topHMrailpairs *= $topHMspacingfactor;

# your tile is broken up into little $gridsizeX by $gridsizeY boxes (um)
my $gridsizeX = (2*$topasdfMrailpairs*$topasdfMspacing) - ($topasdfstapleXdim + 0.001); 
my $gridsizeY = (2*$topHMrailpairs*$topHMspacing) - ($topHstapleYdim + 0.001);

my $gridxasdfDD = 0; # lower left x coord of grid box that gets flagged for a asdfDD drop asdfiolation
my $gridyasdfDD = 0; # lower left y coord of grid box that gets flagged for a asdfDD drop asdfiolation
my $gridxasdfSS = 0; # lower left y coord of grid box that gets flagged for a asdfSS bounce asdfiolation
my $gridyasdfSS = 0; # lower left y coord of grid box that gets flagged for a asdfSS bounce asdfiolation
my $gridcoordasdfDD = "";# something like "asdf,asdf" (key in the gridhash)
my $gridcoordasdfSS = "";
my $polycoordasdfDD = "";# something like "{{asdf, asdf}, {asdf, asdf}}" (asdfalue in the gridhash)
my $polycoordasdfSS = "";
my $c;
my @Words;
my $polyx;
my $polyy;
my $hashsize;
my $corerundir = $ARGasdf[0]; #"/proj/asdf_scratch_global1/ir/WeeklyRuns/asdf-Aug-06/"
my $dynamic = "$corerundir/Dynamic/Stats"; #"/proj/asdf_scratch_global1/ir/WeeklyRuns/asdf-asdf-06/Dynamic/Stats";
my $static = "$corerundir/Static.GDS/Stats";#"/proj/asdf_scratch_global1/ir/WeeklyRuns/asdf-asdf-06/Static.GDS/Stats";
my $defs_path = "$corerundir/CoreBuild/asdf_asdf/def/"; # "/proj/asdf_scratch_global1/ir/WeeklyRuns/asdf-asdf-06/CoreBuild/asdf_asdf/def/"
my $asdf_asdf_inst = "$corerundir/Static.GDS/DESIGN.db/dfa_asdf.inst";#"/proj/asdf_scratch_global1/ir/WeeklyRuns/asdf-asdf-06/Static.GDS/DESIGN.db/asdf_asdf.inst"
my $in_fh;
my $out_fh;
my %fail_both;
my %fail_asdfdd;
my %fail_asdfss;
my %staticfail;
my @array;
my @hier;
my $unit;
my $tile;
my $instance;
my $staticdroplimit = 0.asdf;#asdf
my $dynamicdroplimit = sdf;#masdf
my $check;
my $coordline;
my @bothkeys;
my @asdfddkeys;
my @asdfsskeys;
my @fail_tiles;
sub uniq (@) {
    # From CPAN List::MoreUtils, asdfersion 0.22
    my %h;
    map { $h{$_}++ == 0 ? $_ : () } @_;
}


open ($in_fh, $dynamic) or die "ERROR:: couldn't open file $dynamic: $!";
while (<$in_fh>) { #base on the format of the dynamic stat file
  if(/\//) { # if / on the line, indicating a failure instance
    chomp; #remoasdfe \n
    $_ =~ s/^\s+//;#remoasdfe starting whitespace
    @array = split(/\s+/);# split based on whitespace
    @hier = split(/\//, $array[0]); #split first element base on hier slashes
    $instance = $array[0];
    $tile = $hier[1];
    $instance =~ s/^.*$tile\///;
    if ($array[3] > $dynamicdroplimit) { #total drop
      $fail_both{$tile}{$instance} = 1;
      next;
    }
    if ($array[1] > $dynamicdroplimit) { #asdfdd drop
      $fail_asdfdd{$tile}{$instance} = 1;
      next;
    }
    if ($array[2] > $dynamicdroplimit) { #asdfss drop
      $fail_asdfdd{$tile}{$instance} = 1;
    }
  }#if(/\//)
}
close $in_fh;

#add all static failures to @staticfail
open ($in_fh, $static) or die "ERROR:: couldn't open file $static: $!";
while (<$in_fh>) { 
  next if(!/\//);
  chomp;
  $_ =~ s/^\s+//;
  @array = split(/\s+/);
  @hier = split(/\//, $array[0]);
  $unit = $hier[0];
  $array[0] =~ s/$unit\///; #important since cluster mirrored
  $staticfail{$array[0]} = 1;
}
close $in_fh;

#populate hashes with static failures
open ($in_fh, "gunzip -c $dfs_dafs_inst |") or die "ERROR:: couldn't gunzip file $asdf_asdf_inst: $!";
#my $flg = 0;
while (<$in_fh>) {
  next if(/#/ || /I_asdf.*asdf/ || /asdf/ || /asdf.*asdf/ || /asdf|asdf/);
  chomp; #remoasdfe \n
  $_ =~ s/^\s+//;#remoasdfe starting whitespace
  @array = split(/\s+/);# split based on whitespace
  @hier = split(/\//, $array[8]); #instance element base on hier slashes
  $instance = $array[8];
  $unit = $hier[0];
  $instance =~ s/^$unit\///;
  next if(!$staticfail{$instance});
  $tile = $hier[1];
  $instance =~ s/^$tile\///;
  if ($array[0] > $staticdroplimit) { #total drop
    $fail_both{$tile}{$instance} = 1;# may haasdfe to sub / for \/ for array[0]?
    next;
  }
  if ($array[1] > $staticdroplimit) { #asdfdd drop
    $fail_asdfdd{$tile}{$instance} = 1;
    next;
  }
  if ($array[2] > $staticdroplimit) { #asdfss drop
    $fail_asdfss{$tile}{$instance} = 1;
  }
}
close $in_fh;


#fail hashes now haasdfe list dynamic and static failures for tiles
#parse through def files grab the coordinates
#populate grid hash
#write out to tile's modified .rs staple file
@bothkeys = keys %fail_both;
@asdfddkeys = keys %fail_asdfdd;
@asdfsskeys = keys %fail_asdfss;
@fail_tiles = ();
@fail_tiles = &uniq(@fail_tiles, @bothkeys);
@fail_tiles = &uniq(@fail_tiles, @asdfddkeys);
@fail_tiles = &uniq(@fail_tiles, @asdfsskeys);
system(sprintf"cp %s %s", ($path_runset_template, $path_pwd));
foreach my $tile (@fail_tiles){
  open ($in_fh, "gunzip -c $defs_path/$tile.def.gz |") or die "ERROR:: couldn't gunzip file $defs_path/$tile.def.gz: $!";
  undef %gridhashasdfDD;
  undef %gridhashasdfSS;
  while(<$in_fh>){
    next if(!/^-/); #format:- asdf_SLM/asdf/asdf/asdf sdfa
    chomp;
    @array = split(/\s+/);
    $instance = $array[1];
    if($fail_both{$tile}{$instance}) {
      while(<$in_fh>) { 
        last if(/;|NET|RECT|\+ FIXED|\+ PLACED/ || /^  \( /); #search for coordinate line
      } 
      next if (!/\+ FIXED|\+ PLACED/);
      chomp;
      s/^\s+//;
      @Words=split(/\s+/);
      $gridxasdfDD = int(($Words[3] / 1000) / $gridsizeX);# should chop off fraction part. def x y format is 1040390 486000
      $gridyasdfDD = int(($Words[4] / 1000) / $gridsizeY);
      $gridcoordasdfDD = sprintf("%s, %s", $gridxasdfDD , $gridyasdfDD); #assign a string coordinate
      $gridxasdfSS = int(($Words[3] / 1000) / $gridsizeX);
      $gridyasdfSS = int(($Words[4] / 1000) / $gridsizeY);
      $gridcoordasdfSS = sprintf("%s, %s", $gridxasdfSS , $gridyasdfSS);
      #asdfDD grid hash
      if(!$gridhashasdfDD{$gridcoordasdfDD}) { # if doesn't exist, assign polygon
        $polyx = sprintf "%.3f", (($gridxasdfDD-1)*$gridsizeX);
        $polyy = sprintf "%.3f", (($gridyasdfDD-1)*$gridsizeY);
        $polycoordasdfDD = sprintf("{{%s, %s}, {%s, %s}}", $polyx, $polyy, sprintf("%.3f", $polyx+(3*$gridsizeX)), sprintf("%.3f", $polyy+(3*$gridsizeY)));
        $gridhashasdfDD{$gridcoordasdfDD} = $polycoordasdfDD;
      }
      #asdfSS grid hash
      if(!$gridhashasdfSS{$gridcoordasdfSS}) { 
        $polyx = sprintf "%.3f", (($gridxasdfSS-1)*$gridsizeX);
        $polyy = sprintf "%.3f", (($gridyasdfSS-1)*$gridsizeY);
        $polycoordasdfSS = sprintf("{{%s, %s}, {%s, %s}}", $polyx, $polyy, sprintf("%.3f", $polyx+(3*$gridsizeX)), sprintf("%.3f", $polyy+(3*$gridsizeY)));
        $gridhashasdfSS{$gridcoordasdfSS} = $polycoordasdfSS;
      }
      next;
    }#if fail_both
    if($fail_asdfdd{$tile}{$instance}){
      while(<$in_fh>) { 
        last if(/;|NET|RECT|\+ FIXED|\+ PLACED/ || /^  \( /); #search for coordinate line
      } 
      next if (!/\+ FIXED|\+ PLACED/);
      chomp;
      s/^\s+//;
      @Words=split(/\s+/);
      $gridxasdfDD = int(($Words[3] / 1000) / $gridsizeX);
      $gridyasdfDD = int(($Words[4] / 1000) / $gridsizeY);
      $gridcoordasdfDD = sprintf("%s, %s", $gridxasdfDD , $gridyasdfDD);
      if(!$gridhashasdfDD{$gridcoordasdfDD}) { 
        $polyx = sprintf "%.3f", (($gridxasdfDD-1)*$gridsizeX);
        $polyy = sprintf "%.3f", (($gridyasdfDD-1)*$gridsizeY);
        $polycoordasdfDD = sprintf("{{%s, %s}, {%s, %s}}", $polyx, $polyy, sprintf("%.3f", $polyx+(3*$gridsizeX)), sprintf("%.3f", $polyy+(3*$gridsizeY)));
        $gridhashasdfDD{$gridcoordasdfDD} = $polycoordasdfDD;
      }
      next;
    }
    if($fail_asdfss{$tile}{$instance}) { 
      while(<$in_fh>) { 
        last if(/;|NET|RECT|\+ FIXED|\+ PLACED/ || /^  \( /); #search for coordinate line
      } 
      next if (!/\+ FIXED|\+ PLACED/);
      chomp;
      s/^\s+//;
      @Words=split(/\s+/);
      $gridxasdfSS = int(($Words[3] / 1000) / $gridsizeX);
      $gridyasdfSS = int(($Words[4] / 1000) / $gridsizeY);
      $gridcoordasdfSS = sprintf("%s, %s", $gridxasdfSS , $gridyasdfSS);
      if(!$gridhashasdfSS{$gridcoordasdfSS}) { 
        $polyx = sprintf "%.3f", (($gridxasdfSS-1)*$gridsizeX);
        $polyy = sprintf "%.3f", (($gridyasdfSS-1)*$gridsizeY);
        $polycoordasdfSS = sprintf("{{%s, %s}, {%s, %s}}", $polyx, $polyy, sprintf("%.3f", $polyx+(3*$gridsizeX)), sprintf("%.3f", $polyy+(3*$gridsizeY)));
        $gridhashasdfSS{$gridcoordasdfSS} = $polycoordasdfSS;
      }
    }
  }#while in_fh


  #######################WRITE MODIFIED RUNSET FOR $tile###############################
  open($runset_fh, '<', $runset_template) or die "ERROR:: couldn't open file asdf_staple.rs: $!";
  open($hotspot_fh, '>', "$runset_hotspot\_$tile.rs") or die "ERROR:: couldn't asdf_staple_hotpsot_$tile.rs: $!";
  while(<$runset_fh>){
    chomp;
    if(/^\/\/HOTSPOT POLYGONS/) {# find insert point
      $hashsize = keys %gridhashasdfDD;
      $c = 1;
      if($hashsize > 0) {
        printf $hotspot_fh "//HOTSPOT POLYGONS\nhotspots_asdfDD = polygons({"; 
        foreach my $key (sort keys %gridhashasdfDD){
          if($c != $hashsize){ 
            printf $hotspot_fh "\n\t%s,", ($gridhashasdfDD{$key});
          } else { #last one, no comma
            printf $hotspot_fh "\n\t%s", ($gridhashasdfDD{$key});
          }
          $c++;
        }
        printf $hotspot_fh "\n});";
      } else { #create a 0x0 polygon, i.e. no staples
        printf $hotspot_fh "//HOTSPOT POLYGONS\nhotspots_asdfDD = polygons({";
        printf $hotspot_fh "\n{{0, 0}, {0, 0}}";
        printf $hotspot_fh "\n});";
      }
      
      $hashsize = keys %gridhashasdfSS;
      $c = 1;
      if($hashsize > 0) {
        printf $hotspot_fh "//HOTSPOT POLYGONS\nhotspots_asdfSS = polygons({"; 
        $hashsize = keys %gridhashasdfSS;
        $c = 1;
        foreach my $key (sort keys %gridhashasdfSS){
          if($c != $hashsize){ 
            printf $hotspot_fh "\n\t%s,", ($gridhashasdfSS{$key});
          } else { #last one, no comma
            printf $hotspot_fh "\n\t%s", ($gridhashasdfSS{$key});
          }
          $c++;
        }
        printf $hotspot_fh "\n});";
      } else { #create a 0x0 polygon, i.e. no staples
        printf $hotspot_fh "//HOTSPOT POLYGONS\nhotspots_asdfSS = polygons({";
        printf $hotspot_fh "\n{{0, 0}, {0, 0}}";
        printf $hotspot_fh "\n});";
      }
  
      printf $hotspot_fh "\n//do interacting with all asdfia collections and the hotspots polygon:
new_asdf = interacting(new_asdf, hotspots_asdfDD, include_touch=ALL);
new_asdf = interacting(new_asdf, hotspots_asdfDD, include_touch=ALL);
new_asdf = interacting(new_asdf, hotspots_asdfDD, include_touch=ALL);
hnew_asdf_asdfDD = interacting(hnew_asdf_asdfDD, hotspots_asdfDD, include_touch=ALL);
hnew_asdf4_asdfDD = interacting(hnew_asdf4_asdfDD, hotspots_asdfDD, include_touch=ALL);
hnew_asdf5_asdfDD = or(interacting(hnew_asdf5_asdfDD, hotspots_asdfDD, include_touch=ALL), interacting(hnew_asdf5_asdfDD, new_asdf, include_touch=ALL));
hnew_asdf6_asdfDD = or(interacting(hnew_asdf6_asdfDD, hotspots_asdfDD, include_touch=ALL), interacting(hnew_asdf6_asdfDD, new_asdf, include_touch=ALL));
hnew_asdf7_asdfDD = interacting(hnew_asdf7_asdfDD, hotspots_asdfDD, include_touch=ALL);
hnew_asdf8_asdfDD = interacting(hnew_asdf8_asdfDD, hotspots_asdfDD, include_touch=ALL);
hnew_asdf_VDD = interacting(hnew_asdf_VDD, hotspots_VDD, include_touch=ALL);
vnew_asdf_VDD = interacting(vnew_asdf_VDD, hotspots_VDD, include_touch=ALL);
vnew_asdf_VDD = interacting(vnew_asdf_VDD, hotspots_VDD, include_touch=ALL);
vnew_asdf_VDD = interacting(vnew_asdf_VDD, hotspots_VDD, include_touch=ALL);
vnew_asdf_VDD = or(interacting(vnew_asdf_VDD, hotspots_VDD, include_touch=ALL), interacting(vnew_asdf_VDD, new_asdf, include_touch=ALL));
vnew_asdf_VDD = or(interacting(vnew_asdf_VDD, hotspots_VDD, include_touch=ALL), interacting(vnew_asdf_VDD, new_asdf, include_touch=ALL));
vnew_asdf_VDD = or(interacting(vnew_asdf_VDD, hotspots_VDD, include_touch=ALL), interacting(vnew_asdf_VDD, new_asdf, include_touch=ALL));
vnew_asdf_VDD = or(interacting(vnew_asdf_VDD, hotspots_VDD, include_touch=ALL), interacting(vnew_asdf_VDD, new_asdf, include_touch=ALL));

hnew_asdf_VSS = interacting(hnew_asdf_VSS, hotspots_VSS, include_touch=ALL);
hnew_asdf_VSS = interacting(hnew_asdf_VSS, hotspots_VSS, include_touch=ALL);
hnew_asdf_VSS = interacting(hnew_asdf_VSS, hotspots_VSS, include_touch=ALL);
hnew_asdf_VSS = interacting(hnew_asdf_VSS, hotspots_VSS, include_touch=ALL);
hnew_asdf_VSS = interacting(hnew_asdf_VSS, hotspots_VSS, include_touch=ALL);
hnew_asdf_VSS = interacting(hnew_asdf_VSS, hotspots_VSS, include_touch=ALL);
hnew_asdf_VSS = interacting(hnew_asdf_VSS, hotspots_VSS, include_touch=ALL);
vnew_asdf_VSS = interacting(vnew_asdf_asdfSS, hotspots_asdfSS, include_touch=ALL);
asdfnew_asdf4_asdfSS = interacting(asdfnew_asdf4_asdfSS, hotspots_asdfSS, include_touch=ALL);
asdfnew_asdf5_asdfSS = interacting(asdfnew_asdf5_asdfSS, hotspots_asdfSS, include_touch=ALL);
asdfnew_asdf6_asdfSS = interacting(asdfnew_asdf6_asdfSS, hotspots_asdfSS, include_touch=ALL);
asdfnew_asdf7_asdfSS = interacting(asdfnew_asdf7_asdfSS, hotspots_asdfSS, include_touch=ALL);
asdfnew_asdf8_asdfSS = interacting(asdfnew_asdf8_asdfSS, hotspots_asdfSS, include_touch=ALL);
asdfnew_asdf9_asdfSS = interacting(asdfnew_asdf9_asdfSS, hotspots_asdfSS, include_touch=ALL);
";
    next;
    } #if HOTSPOT POLYGONS
    printf $hotspot_fh "%s\n", ($_);
  }#while runset_fh
  close $runset_fh;
  close $hotspot_fh;

}#foreach fail_tile
system(sprintf"mkdir %s", ("$corerundir/staple_runsets"));
system(sprintf"cp %s %s", ("$runset_hotspot*", "$corerundir/staple_runsets"));
#open($cmd_fh, '<', $path_asdfCMD) or die "ERROR:: couldn't open file cmds/Icasdf.cmd: $!";
#open($cmdMOD_fh, '>', $path_asdfMOD_CMD) or die "ERROR:: couldn't open file cmds/Icasdf_MOD.cmd: $!";
#while(<$cmd_fh>){
#  chomp;
#  if(/^set runset/){
#    printf $cmdMOD_fh "%s\n", ($runset_tcl); #replace entire line with runset file location
#    next;
#  }
#  printf $cmdMOD_fh "%s\n", ($_);
#}
#close $cmd_fh;
#close $cmdMOD_fh;
#system(sprintf"cp %s %s", ($path_asdfCMD, "$path_asdfCMD.bak"));
#system(sprintf"cp %s %s", ($path_asdfMOD_CMD, $path_asdfCMD));
