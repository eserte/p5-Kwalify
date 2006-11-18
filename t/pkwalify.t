#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: pkwalify.t,v 1.1 2006/11/18 00:36:49 eserte Exp $
# Author: Slaven Rezic
#

use strict;
use FindBin;

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "1..0 # skip: no Test::More module\n";
	exit;
    }
}

plan tests => 2;

my $script = "pkwalify";
my @cmd = ($^X, "-Mblib", $script);

for my $def (["schema05.yaml", "document05a.yaml", 1],
	     ["schema05.yaml", "document05b.yaml", 0],
	    ) {
    my($schema_file, $data_file, $expect_validity) = @$def;
    $_ = "$FindBin::RealBin/testdata/$_" for ($schema_file, $data_file);
    
    my @cmd = @cmd;
    push @cmd, -f => $schema_file, $data_file;
    system(@cmd);
    my $valid = $? == 0 ? 1 : 0;
    is($valid, $expect_validity, "@cmd");
}

__END__
