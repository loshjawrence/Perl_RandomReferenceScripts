#!tool/pandora64/bin/perl 
#!/usr/bin/perl -d
#use warnings;
use strict;
use Data::Dumper;
if ($#ARGV < 0) {  die "ERROR: No .x file given\nUsage: perlscript then .x file\n"; }
my $dir = $ARGV[0];
my ($linenum,$in_fh,$in_gate,@files,$file,@splitline,%signals,@array,$full_sig,$base_sig,$idx,$idxd_sig,$state);


#COMPILED REGEX'S:
#match gate or dff declaration
my $START = qr/dff|gate\s*\(/;
#match end of declaration
my $STOP = qr/\)\s*;/;
#match comment
my $COMMENT = qr/\/\//;
#match signal[`iterator] strings
my $SIG_ITERATOR = qr/[a-zA-Z]+[a-zA-Z0-9_:`]*\[{1}`{1}[a-zA-Z]+[a-zA-Z0-9_]*\]{1}/;
#match var names in front of open bracket
my $FULL_SIG_NAME = qr/[a-zA-Z]+[a-zA-Z0-9_:`]*/;
my $BASE_SIG_NAME = qr/[a-zA-Z]+[a-zA-Z0-9_:]*/;
my $IDXD_SIG_NAME = qr/`{1}[a-zA-Z]+[a-zA-Z0-9_:]*/; 
#match bracket group
my $BETWEEN_BRACKETS = qr/\[{1}`{1}[a-zA-Z]+[a-zA-Z0-9_]*\]{1}/;
#find any lower case letters or numbers
my $LOWER_CASE_LETTERS = qr/[a-z]+/;

sub printMultipleIteratorsForSignal {
  if (@_ != 2) { 
    print "ERROR: &printMultipleIteratorsForSignal needs state and file passed to it.\n";
  } elsif (/\?/) {#ignore mux
  } else { 
    my($p_state,$p_file) = @_;#assign first to p_state, second to p_file
    if ($p_state) {#line continuation of gate(... or dff(...
      @array = /($SIG_ITERATOR)/g;
    } else {#first line where gate( or dff( is declared
      @splitline = split(/,/);
      #find all matches in $splitline[1], assign to @array in list form
      @array = $splitline[1] =~ /($SIG_ITERATOR)/g;
    }
    foreach my $item (@array) { 
      #assign 1st match in 2nd var to 1st var
      $full_sig = $1 if $item =~ /($FULL_SIG_NAME)/;
      $idx = $1 if $item =~ /($BETWEEN_BRACKETS)/;
      if ($idx =~ /$LOWER_CASE_LETTERS/) { #idx is not a tic define
        if (exists $signals{$full_sig}) {
          if ($signals{$full_sig} ne $idx) { 
             print "FILE: $p_file\nLine number: $linenum\nPossible crossbar, multiple iterators on same bus:\n";
             print "\tsignal: $full_sig\n\titerators: $signals{$full_sig}, $idx\n";
          }
        } else {
          $signals{$full_sig} = $idx;
        }
      } else { #idx is a tic define
        $base_sig = $1 if $full_sig =~ /($BASE_SIG_NAME)/;
        $idxd_sig = $1 if $full_sig =~ /($IDXD_SIG_NAME)/;
        if (exists $signals{$base_sig}) {
          if ($signals{$base_sig} ne $idxd_sig) { 
             print "FILE: $p_file\nLine number: $linenum\nPossible crossbar, multiple iterators on same bus:\n";
             print "\tsignal: $base_sig\n\titerators: $signals{$base_sig}, $idxd_sig\n";
          }
        } else {
          $signals{$base_sig} = $idxd_sig;
        }
      }
    }
  }
}

@files = glob("$dir/*.x");
foreach $file (@files) {
#  print "FILE: $file\n";
  open ($in_fh, $file) or die "ERROR:: couldn't open file $file: $!";
  $linenum = $in_gate = 0;
  while (<$in_fh>) {
    $linenum++;
    if(/$START/ && !/$COMMENT/) {
      $state = 0;
      &printMultipleIteratorsForSignal($state,$file);
      if(/$STOP/ && !/$COMMENT/) {
        $in_gate = 0;
        undef %signals; 
      } else {
        $in_gate = 1;
      }
    #end if START
    } elsif (/$STOP/ && !/$COMMENT/) {
      $state = 1;
      &printMultipleIteratorsForSignal($state,$file);
      $in_gate = 0;
      undef %signals; 
    #end elsif STOP
    } elsif ($in_gate  && !/$COMMENT/) {
      $state = 1;
      &printMultipleIteratorsForSignal($state,$file);
    #end elsif in_gate
    } else {
    #end else
    }
  #end while in_fh
  }
  close $in_fh;
}
exit 0;
