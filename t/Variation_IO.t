# -*-Perl-*-
## Bioperl Test Harness Script for Modules
## $Id$

use strict;

BEGIN {
	use vars qw($NUMTESTS $error);
	$error = 0;
	eval { require Test; };
	if( $@ ) {
		use lib 't';
	}
	use Test;

	eval {
		require Text::Wrap;
		require XML::Writer;
	};
	if ( $@ || $Text::Wrap::VERSION < 98 ) {
		print STDERR "Skip tests - missing Text::Wrap 98 installed or XML::Writer\n";
		$error = 1;
	}
	$NUMTESTS = 25;
	plan tests => $NUMTESTS;
}

END {
    foreach ( $Test::ntest..$NUMTESTS) {
        skip("Missing dependencies. Skipping tests",1);
    }
}

if ($error == 1 ) {
	exit(0);
}

use Bio::Variation::IO;
use Bio::Root::IO;

sub fileformat ($) {
	my ($file) = shift;
	my $format;
	if ($file =~ /.*dat$/) {
		$format = 'flat';
	}
	elsif ($file =~ /.*xml$/ ) {
		$format = 'xml';
	} else {
		print "Wrong extension! [$file]";
		exit;
	}
	return $format;
}

sub ext ($) {
	my ($file) = @_;
	my ($name) = $file =~ /.*.(...)$/;
	return $name;
}

sub filename ($) {
	my ($file) = @_;
	my ($name) = $file =~ /(.*)....$/;
	return $name;
}

sub io {
    my ($t_file, $o_file) = @_; 
    my $res;

    my ($t_ext) = ext ($t_file);
    my ($o_ext) = ext ($o_file);
    my ($t_format) = fileformat ($t_file);
    my ($o_format) = fileformat ($o_file);
    my ($t_name) = filename($t_file);
    my ($o_name) = filename($o_file);

    my( $before );
    {
        local $/ = undef;
        local *BEFORE;
        open BEFORE, "$t_name.$o_ext";
        $before = <BEFORE>;
        close BEFORE;
    }

    ok $before;#"Error in reading input file [$t_name.$o_ext]";

    my $in = Bio::Variation::IO->new( -file => $t_file);
    my  @entries ;
    while (my $e = $in->next) {
        push @entries, $e;
    }
    my $count = scalar @entries;
    ok @entries > 0;# "No SeqDiff objects [$count]";

    my $out = Bio::Variation::IO->new( -FILE => "> $o_file", 
				       -FORMAT => $o_format);
    my $out_ok = 1;
    foreach my $e (@entries) {
        $out->write($e) or $out_ok = 0;
    }
    undef($out);  # Flush to disk
    ok $out_ok;#  "error writing variants";

    my( $after );
    {
        local $/ = undef;
        local *AFTER;
        open AFTER, $o_file;
        $after = <AFTER>;
        close AFTER;
    }

    ok $after;# "Error in reading in again the output file [$o_file]";
    ok $before, $after, "test output file differs from input";
    print STDERR `diff $t_file $o_file` if $before ne $after;
    unlink($o_file); 
}

io  (Bio::Root::IO->catfile("t","data","mutations.dat"), 
     Bio::Root::IO->catfile("t","data","mutations.out.dat")); #1..5
io  (Bio::Root::IO->catfile("t","data","polymorphism.dat"), 
     Bio::Root::IO->catfile("t","data","polymorphism.out.dat")); #6..10

eval {
    require Bio::Variation::IO::xml;
};

if( $@ ) {
    print STDERR
	 "\nThe XML-format conversion requires the CPAN modules ",
	 "XML::Twig, XML::Writer, and IO::String to be installed ",
	 "on your system, which they probably aren't. Skipping these tests.\n";
    for( $Test::ntest..$NUMTESTS) {
	 skip("No XML::Twig installed", 1);
    }
    exit(0);
}

eval {
    if( $XML::Writer::VERSION >= 0.5 ) { 
	io  (Bio::Root::IO->catfile("t","data","mutations.xml"), 
	     Bio::Root::IO->catfile("t","data","mutations.out.xml")); #10..12
    } else { 
	io  (Bio::Root::IO->catfile("t","data","mutations.old.xml"), 
	     Bio::Root::IO->catfile("t","data","mutations.out.xml")); #10..12
    }
};

eval {
    if( $XML::Writer::VERSION >= 0.5 ) { 
	io  (Bio::Root::IO->catfile("t","data","polymorphism.xml"), 
	     Bio::Root::IO->catfile("t","data","polymorphism.out.xml")); #13..14
    } else { 
	io  (Bio::Root::IO->catfile("t","data","polymorphism.old.xml"), 
	     Bio::Root::IO->catfile("t","data","polymorphism.out.xml")); #13..14

    }
};

eval { 
    if( $XML::Writer::VERSION >= 0.5 ) { 
	io  (Bio::Root::IO->catfile("t","data","mutations.dat"), 
	     Bio::Root::IO->catfile("t","data","mutations.out.xml")); #15..25
    } else { 
	io  (Bio::Root::IO->catfile("t","data","mutations.old.dat"), 
	     Bio::Root::IO->catfile("t","data","mutations.old.out.xml")); #15..25
    }
};
