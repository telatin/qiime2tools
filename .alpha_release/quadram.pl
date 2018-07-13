#!/usr/bin/env perl

use strict;
use warnings;

use Term::ANSIColor  qw(:constants);

my $logo = '
                            OO
                         OOO O
                    OOOOO    O
                 OOO         O
             OOOO            O
          OOO                O
      OOOO                   O
     O                       O
      O     .................O-------------------+
      OO    .................O-------------------|
       O    .................O                  ||
        O   .................O                  ||
         OO .................O                  ||
          OO...............OOO                  ||
           O...........OOOOO                    ||
           OO.....OOOOOO                        ||
            OOOOOO                              ||
            ||                                  ||
            ||                                  ||  
            ||       Q  U  A  D  R  A  M        ||
            ||                                  ||
            ||    I  n  s  t  i  t  u  t  e     ||
            ||                                  ||
            |------------------------------------|
            +------------------------------------+
';


printlogo($logo);

sub printlogo {
	print "\n";
	my $logo = shift(@_);
	my @chars = split //, $logo;
	foreach my $c (@chars) {
		if ($c eq 'O') {
			print BOLD GREEN $c;
		} elsif ($c eq '.') {
      print GREEN $c;
    } elsif ($c =~/[\W|]/) {
			print BOLD $c;
		} else {
			print BOLD YELLOW $c;
		}

		print RESET;
	}

	print "\n";
}