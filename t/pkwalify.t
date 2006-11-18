#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: pkwalify.t,v 1.4 2006/11/18 13:22:13 eserte Exp $
# Author: Slaven Rezic
#

use strict;
use FindBin;
use Getopt::Long;

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "1..0 # skip: no Test::More module\n";
	exit;
    }
}

my @yaml_syck_defs = (["schema05.yaml", "document05a.yaml", 1],
		      ["schema05.yaml", "document05b.yaml", 0],
		     );
my @json_defs = ();

my $v;
GetOptions("v!")
    or die "usage: $0 [-v]";

plan tests => scalar(@yaml_syck_defs) + scalar(@json_defs);

my $script = "pkwalify";
my @cmd = ($^X, "-Mblib", $script);

SKIP: {
    skip("Need YAML::Syck for tests", scalar(@yaml_syck_defs))
	if !eval { require YAML::Syck; 1 };

    for my $def (@yaml_syck_defs) {
	any_test($def);
    }
}

SKIP: {
    skip("Need JSON for tests", scalar(@json_defs))
	if !eval { require JSON; 1 };

    for my $def (@json_defs) {
	any_test($def);
    }
}

sub any_test {
    my($def) = @_;
    local $Test::Builder::Level = $Test::Builder::Level+1;
    my($schema_file, $data_file, $expect_validity) = @$def;
    for ($schema_file, $data_file) {
	$_ = "$FindBin::RealBin/testdata/$_";
    }
    
    my @cmd = @cmd;
    push @cmd, '-f' => $schema_file, $data_file;

    my $valid;
    if (eval { require IPC::Run; 1 }) {
	my($stdin,$stdout,$stderr);
	if (!IPC::Run::run(\@cmd, \$stdin, \$stdout, \$stderr)) {
	    $valid = 0;
	    diag $stderr if $v;
	} else {
	    $valid = 1;
	}
    } else {
	system(@cmd);
	$valid = $? == 0 ? 1 : 0;
    }
    is($valid, $expect_validity, "@cmd");
}

__END__
