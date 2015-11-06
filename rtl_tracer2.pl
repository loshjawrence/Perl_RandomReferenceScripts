#!tool/pandora64/bin/perl 
#!/usr/bin/perl -d
#use warnings;
use strict;
use POSIX;
use Data::Dumper;



#Some test signals:
#perl -d /home/jlawrenc/bin/perl/rtl_tracer2.pl data/SynRtl/asdf_asdf_q.x.v asdf_asdf_asdf
#perl -d /home/jlawrenc/bin/perl/rtl_tracer2.pl data/SynRtl/asdf_asdf_q.x.v sdf_asdf_sdf_dfas
#perl -d /home/jlawrenc/bin/perl/rtl_tracer2.pl data/SynRtl/asdf_asdf_q.x.v asdf_asdf_sdf_asdf
#perl -d /home/jlawrenc/bin/perl/rtl_tracer2.pl data/SynRtl/asdf_asdf_q.x.v asdf_asdf_asdf_asdf
#many buses (start at input):
#perl -d /home/jlawrenc/bin/perl/rtl_tracer2.pl data/SynRtl/asdf_asdf_q.x.v asdf_asdf_asdf_asdf
if ($#ARGV != 1) { die "ERROR: Need to pass rtl file and signal name\nUsage: perl rtl_tracer.pl <rtl_file> <signal_name>\n"; }
my ($rtl_file,$startsig) = @ARGV;
my ($in_fh,$out_fh,$state);
my ($found,$record,$no_hits,$foundpoint) = (0,0,1,0);
my ($out_file,$logic,$strippedline) = ("rtl_trace.v","","");
my (@searcharray,@hasharray);
my (%h_hits,%h_insigs,%h_outsigs,%h_trace,%h_full);
$h_insigs{$startsig} = 0;
$h_outsigs{$startsig} = 0;
$h_full{$startsig} = 0;
my $insigs = join("|", keys %h_insigs);
my $outsigs = join("|", keys %h_outsigs);
print "OUTFILE: $out_file\n";

#COMPILED REGEX'S:
my $OUTPUT = qr/output/;
my $INPUT = qr/input/;
my $SEMI = qr/;/;
my $COMMENT = qr/\/\/.*$/;
my $LINECOMMENT = qr/^\s*\/\//;
my $SPACE = qr/\s+/;
my $BRACKETS = qr/[\(\)\{\}\[\]]/;
my $MACRO = qr/`[A-Z0-9_\-]+/;
my $IDX = qr/\[[A-Z0-9_:\-]+\]/;
my $OPS  = qr/[|&!()]/;
my $BITS = qr/[0-9]+`b[0-9a-z]+/;
my $SIG = qr/[A-Z]+[a-zA-Z0-9_]+[a-z]+[a-zA-Z0-9_]+/;
my $ASSIGN = qr/^\s+assign\s+/;
my $NL = qr/\n+/;
my $COMMA = qr/,/;
my $KEYWORDS = qr/assign|input|output|dff__|cg__|enc|dec|case|as_struct_muxi/;
open ($out_fh, ">", $out_file) or die "ERROR:: couldn't open file $out_file: $!\n";

sub removeSearchTerm {
  my (@p_searches,$p_search_to_remove) = @_;
  my ($p_index) = grep { $p_searches[$_] =~ /$p_search_to_remove/ } 0..$#p_searches;
  splice(@p_searches,$p_index,1);
  return @p_searches;
}
sub capture {
  my ($p_ins,$p_outs) = @_;
  my (%h_infound,%h_outfound,@inhits,@outhits);
  $h_infound{$_} = 0 for (split($SPACE, $p_ins));
  $h_outfound{$_} = 0 for (split($SPACE, $p_outs));
  #check if any h_outsigs in h_infound
  my $write = 0;
  foreach my $key (keys %h_infound) {
    if (exists $h_outsigs{$key}) {
      my $outstring = join(" ", sort(keys %h_outfound));
      if (exists $h_trace{$outstring}) {
        $write = 1;   
        foreach my $hey (@{$h_trace{$outstring}}) {
          if ($logic eq $hey) { $write = 0; }
        }
      } else {
        $write = 1;
      } 
    }
  }
  #check if any h_insigs in h_outfound
  if (!$write){
    foreach my $key (keys %h_outfound) {
      if (exists $h_insigs{$key}) {
        my $outstring = join(" ", sort(keys %h_outfound));
        if (exists $h_trace{$outstring}) {
          $write = 1;
          foreach my $hey (@{$h_trace{$outstring}}) {
            if ($logic eq $hey) { $write = 0; } #turn off if match
          }
        } else {
          $write = 1;
        }
      }
    }
  }
  if ($write) {
    my $outstring = join(" ", sort(keys %h_outfound));
    if (exists $h_trace{$outstring}) {
      my $new = 1;
      foreach my $hey (@{$h_trace{$outstring}}) {
        if ($logic eq $hey) { $new = 0; }
      }
      if ($new) {
        push @{$h_trace{$outstring}}, $logic;
      }
    } else {
      push @{$h_trace{$outstring}}, $logic;
    }

    #add any new infounds to insigs
    if ($foundpoint < 0) { #startpoint was found, dont record input pin
    } else {
      foreach my $key (keys %h_infound) {
        if (exists $h_outsigs{$key}) {
        } else {
          $h_insigs{$key} = 0;
        }
      }
    }
    #add any new outfounds to outsigs
    if ($foundpoint > 0) { #endpoint was found, dont record output pin
    } else {
      foreach my $key (keys %h_outfound) {
        if (exists $h_insigs{$key}) {
        } else { 
          $h_outsigs{$key} = 0;
        }
      }
    }

    $insigs = join("|", (keys %h_insigs));
    $outsigs = join("|", (keys %h_outsigs));
    $h_full{$_} = 0 for (split("\\|", "$insigs|$outsigs"));
    $no_hits = 0;
  }
}

sub assignEq { #combo
  my ($p_left,$p_right) = split("=", $logic);
  $p_left = join(" ", ($p_left =~ /$SIG/g));
  $p_right = join(" ", ($p_right =~ /$SIG/g));
  &capture($p_right,$p_left);
}
sub inputEq { #input
   my $p_inputsig = $_;
   $p_inputsig =~ s/$NL|$SPACE|$INPUT|$IDX|$MACRO|$COMMENT|$SEMI|$BRACKETS|$COMMA//g;
   my @p_signamearray = split("\\|", $insigs);
   if (exists $h_trace{$p_inputsig}) { 
      my $new = 1;
      foreach my $hey (@{$h_trace{$p_inputsig}}) {
        if ($logic eq $hey) { $new = 0; }
      }
      if ($new) {
        push @{$h_trace{$p_inputsig}}, $logic;
        $no_hits = 0;
      }
   } else { push @{$h_trace{$p_inputsig}}, $logic; $no_hits = 0;}
}
sub outputEq { #output 
   my $p_outputsig = $_;
   $p_outputsig =~ s/$NL|$SPACE|$OUTPUT|$IDX|$MACRO|$COMMENT|$SEMI|$BRACKETS|$COMMA//g;
   my @p_signamearray = split("\\|", $insigs);
   if (exists $h_trace{$p_outputsig}) { 
      my $new = 1;
      foreach my $hey (@{$h_trace{$p_outputsig}}) {
        if ($logic eq $hey) { $new = 0; }
      }
      if ($new) {
        push @{$h_trace{$p_outputsig}}, $logic;
        $no_hits = 0;
      }
   } else { push @{$h_trace{$p_outputsig}}, $logic; $no_hits = 0;}
}
sub dffEq { #flop
  my ($p_name,$p_q,$p_clk,$p_d,$p_sse) = split("\\.", $logic);
  $p_q = join(" ", ($p_q =~ /$SIG/g));
  $p_d = join(" ", ($p_d =~ /$SIG/g));
  #check if sp or ep
  foreach my $sig (split($SPACE,$p_d)) {
    if(exists $h_outsigs{$sig}) { $foundpoint = 1; } #found ep
  } 
  foreach my $sig (split($SPACE,$p_q)) {
    if (exists $h_insigs{$sig}) { $foundpoint = -1; }#found sp
  }
  &capture($p_d,$p_q); $foundpoint = 0;
}
sub cgEq { #gater
  my ($p_name,$p_gclk,$p_clk,$p_en,$p_sse) = split("\\.", $logic);
  $p_gclk = join(" ", ($p_gclk =~ /$SIG/g));
  $p_en = join(" ", ($p_en =~ /$SIG/g));
  #check if sp or ep
  foreach my $sig (split($SPACE,$p_en)) {
    if(exists $h_outsigs{$sig}) { $foundpoint = 1; } #found ep
  } 
  foreach my $sig (split($SPACE,$p_gclk)) {
    if (exists $h_insigs{$sig}) { $foundpoint = -1; }#found sp
  }
  &capture($p_en,$p_gclk); $foundpoint = 0;
}
sub encEq { #encoder
  my ($p_enc,$p_dec) = split(",", $logic);
  my @array = ($p_enc =~ /$SIG/g);
  $p_enc = $array[1];
  $p_dec = join(" ", ($p_dec =~ /$SIG/g));
  &capture($p_dec,$p_enc);
}
sub decEq { #decoder
  my ($p_dec,$p_enc,$p_en) = split(",", $logic);
  my @array = ($p_dec =~ /$SIG/g);
  $p_dec = $array[1];
  $p_enc = join(" ", ($p_enc =~ /$SIG/g));
  $p_en = join(" ", ($p_en =~ /$SIG/g));
  &capture($p_enc,$p_dec);
}
sub caseEq {#case(mux) BROKEN
  my ($p_first,@array) = split(";", $logic);
  my $p_dec = s/^.*\(|\s+|$IDX|$MACRO|$BRACKETS|$COMMA//g;
  my $p_enc = s/\s+|$IDX|$MACRO|$BRACKETS|$COMMA//g; 
  my $p_en = s/\);.*$|\s+|$OPS|$IDX|$MACRO|$BRACKETS|$COMMA//g;
  &capture($p_enc,$p_dec);
}
sub muxEq {#as_struct_muxi
  my ($p_out,$p_ins) = split("{", $logic);
  my @array = ($p_out =~ /$SIG/g);
  $p_out = $array[1];
  @array = split(",", $p_ins);
  my ($p_sel,$p_in) = ($array[1],$array[2]);
  $p_sel = join(" ", ($p_sel =~ /$SIG/g));
  $p_in = join(" ", ($p_in =~ /$SIG/g));
  &capture("$p_sel $p_in",$p_out);
}
sub pickEq {#asdf_q_picker
  my ($p_name,$p_age,$p_thisarb,$p_arb,$p_oldest) = split("\\.", $logic);
  my @array = ($p_age =~ /$SIG/g);
  $p_age = $array[1];
  @array = ($p_thisarb =~ /$SIG/g);
  $p_thisarb = $array[1];
  @array = ($p_arb =~ /$SIG/g);
  $p_arb = $array[1];
  @array =  ($p_oldest =~ /$SIG/g);
  $p_oldest = $array[1];
  &capture("$p_age $p_thisarb $p_arb",$p_oldest);
}
$state=1;
while ($state) {
  open ($in_fh, $rtl_file) or die "ERROR:: couldn't open file $rtl_file: $!\n";
  $no_hits = 1;
  while (<$in_fh>) {
    if ((/$KEYWORDS/ || $record) && $_ !~ /$LINECOMMENT/) {
      $logic = $logic . $_; 
      $strippedline = $_;
      $strippedline = join(" ", ($strippedline =~ /$SIG/g));
      if (/$insigs|$outsigs/) {
        for my $item (split($SPACE, $strippedline)) {
          if (exists $h_full{$item}) { $found = 1; last; }
        }
      }
      #$found = 1 if (/$insigs|$outsigs/); 
      
      if (/;/ && $logic !~ /case /) {
        $record = 0;
        if ($found) { 
          if ($logic =~ /assign /) { &assignEq; $logic = ""; $found = 0;
          } elsif ($logic =~ /input/) { &inputEq; $logic = ""; $found = 0;
          } elsif ($logic =~ /output/) { &outputEq; $logic = ""; $found = 0;
          } elsif ($logic =~ /dff__/) { &dffEq; $logic = ""; $found = 0;
          } elsif ($logic =~ /cg__/) { &cgEq; $logic = ""; $found = 0;
          } elsif ($logic =~ /enc/) { &encEq; $logic = ""; $found = 0;
          } elsif ($logic =~ /dec/) { &decEq; $logic = ""; $found = 0;
          } elsif ($logic =~ /as_struct_muxi/) { &muxEq; $logic = ""; $found = 0;
          } elsif ($logic =~ /picker/) { &pickEq; $logic = ""; $found = 0;
          } else { print "ERROR: found signal but could not find equation type.\n";}
        } else {
          $logic = "";
        }
      } elsif (/endcase/ && $logic =~ /case /) {
        $record = 0;
        &caseEq if $found; $logic = ""; $found = 0;
      } else {
        $record = 1;
      }
    }
  }
  close $in_fh;
  $state = 0 if $no_hits;
}
print $out_fh Dumper \%h_trace;
close $out_fh;
exit 0;
