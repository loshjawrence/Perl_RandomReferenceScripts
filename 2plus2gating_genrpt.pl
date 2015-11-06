#!/usr/bin/perl 
use warnings;
use strict;

my $current_fh; #file handle currently opened file
my $path_optctsdef = "data/OptCts.def.gz";
my $path_gaterMetrics = "rpts/IcPixasdf/enable_cell_and_gater_metrics.asdf.rpt";
my $path_metrics_asdfgaters = "gater_metrics_asdf.asdf.rpt";
my $path_adsfgaterrun;
my %myhash; #hash fields: count cap captot area areatot
my @tmp; 
my @gater_regexs;
my $gaterprefix = "asdf";
my $latchsubstring = "asdf";
my $arraysubstring = "array";
my $c = 0;

#TODO: find these dynamically
my $gatercol = 3;
my $loadcol = 3;
my $areacol = 5;

#perl asdfgating.pl "asdf gater run path"
if(exists $ARGV[0]) {
	$path_asdfgaterrun = $ARGV[0];
	print "Grabbing gater list from $path_asdfgaterrun/tune/asdf/asdf.precompile.tcl\n";
} else {
	die "Please supply the path to the 2 plus 2 gater run directory\n";
}

open ($current_fh, "$path_gaterrun/tune/asdf/asdf.precompile.tcl") or die "ERROR:: couldn't open file asdf.precompile.tcl: $!";

#look through the asdf.precompile.tcl in the asdf gater run dir and make a list of regex's that need to be searched for in the asdf.def 
while(<$current_fh>) {
	chomp;
	if(/set gaters/) {
		while(<$current_fh>) {
			chomp;
			if(/full_name/) {# formatting is like: full_name =~ some/hier/archy
				$_ =~ s/^\s+//;	#remove any white space at the beginning of the line
				@tmp = split(/[\s=~]+/); #split up line based on whitespace and some combination of tcl assignment operator and spaces, add to tmp array
				#if($tmp[1] =~ /"/) { # if theres a trailing quote
				#	$gater_regexs[$c] = substr($tmp[1],0,-1);#return all but last character, which should be a "
				#} else {
					$gater_regexs[$c] = $tmp[1];	
				#}
				$c++;
			}
			if(/]/) {#hit end of set gaters collection declaration
				last;
			}
		}
		last;
	}
}


close $current_fh;

#convert tcl metachars to perl metachars and set up hier names to handle the .def hier separators. example .def hier name: asdf/something\/something\/something
foreach (@gater_regexs) {
	s/\*/\.\*/g;# * becomes .*
	s/\?/\./g;# ? becomes .
	s/\//[\\\\\/]+/g; # / becomes [\\/]+ which tells it to match a '\' or a '/' 1 or more times, needed for the .def hier separators
}
printf "Gater regex's are: \n%s\n", (join("\n", @gater_regexs));

open ($current_fh, "gunzip -c $path_asdfdef |") or die "ERROR:: couldn't gunzip file asdf.def.gz: $!";

#look through the asdf.def and make a hash of gater types, update the count field 
while(<$current_fh>) {
	chomp;
        if(/$gaterprefix/ and not /$latchsubstring/) {
		foreach my $regex (@gater_regexs) {	
			if(/$regex/) {
				$_ =~ s/^\s+//;				#remove any white space at the beginning of the line
    				@tmp = split(/\s+/, $_); 		#split line, add to temp as a whitespace delimited list
                		$myhash{$tmp[$gatercol-1]}{count}++;
				last;
			}
		}
        }
}

close $current_fh;
open ($current_fh, '<', $path_gaterMetrics) or die "ERROR:: couldn't open file enable_cell_and_gater_metrics.asdf.rpt: $!";

#add to hash the pin load and areas of the gater types, keep a running total
while(<$current_fh>){
	chomp;
	foreach my $key (keys %myhash) {
		if(/$key/) {
			$_ =~ s/^\s+//;
			@tmp = split(/\s+/, $_);
			$myhash{$key}{cap} = $tmp[$loadcol-1];	
			$myhash{$key}{captot} = $myhash{$key}{count} * $myhash{$key}{cap};
			$myhash{$key}{area} = $tmp[$areacol-1];
			$myhash{$key}{areatot} = $myhash{$key}{count} * $myhash{$key}{area};
			#keep a running count
			$myhash{"totals"}{count} += $myhash{$key}{count};
 			$myhash{"totals"}{captot} += $myhash{$key}{captot};
			$myhash{"totals"}{areatot} += $myhash{$key}{areatot};
		}	
	}
}

close $current_fh;
open ($current_fh, '>', $path_metrics_asdfgaters) or die "ERROR:: couldn't open file gater_metrics_asdf.asdf.rpt: $!";

printf $current_fh "\t%-30s %5s %20s %15s %20s %15s\n", ("Cell type", "count", "clk pin cap", "pin cap tots", "area per cell", "area tots");
printf $current_fh "\t%-30s %5s %20s %15s %20s %15s\n", ("---------", "-----", "-----------", "------------", "-------------", "---------");
foreach my $key (sort keys %myhash) {
	if($key eq "totals") {
		printf $current_fh "\t%-30s %5s %20s %15s %20s %15s\n", ("", "-----", "", "------------", "", "---------");
		printf $current_fh "\t%-30s %5d %20s %15.6f %20s %15.6f\n", ($key, $myhash{$key}{count}, "", $myhash{$key}{captot}, "", $myhash{$key}{areatot});
        } else {
		printf $current_fh "\t%-30s %5d %20.6f %15.6f %20.6f %15.6f\n", ($key, $myhash{$key}{count}, $myhash{$key}{cap}, $myhash{$key}{captot}, $myhash{$key}{area}, $myhash{$key}{areatot});
	}
}

close $current_fh;

system("cat gater_metrics_asdf.asdf.rpt");
