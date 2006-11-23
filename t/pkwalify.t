#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: pkwalify.t,v 1.5 2006/11/23 20:56:45 eserte Exp $
# Author: Slaven Rezic
#

use strict;
use FindBin;
use Getopt::Long;

BEGIN {
    if (!eval q{
	use Test::More;
	use File::Temp;
	use File::Spec;
	1;
    }) {
	print "1..0 # skip: no Test::More, File::Spec and/or File::Temp modules\n";
	exit;
    }
}

my @yaml_syck_defs = (["schema05.yaml", "document05a.yaml", 1],
		      ["schema05.yaml", "document05b.yaml", 0],
		     );

my %combined_document;
{
    for my $def (["invalid_diff",   "document05a.yaml", "document05b.yaml"],
		 ["valid_same",     "document05a.yaml", "document05a.yaml"],
		 ["invalid_same",   "document05b.yaml", "document05b.yaml"],
		 ["invalid_schema", "schema05.yaml", "schema05.yaml"],
		) {
	my($newname, @yaml) = @$def;

	my($fh,$outfile) = File::Temp::tempfile(SUFFIX => ".yaml",
						UNLINK => 1);

	for my $document (@yaml) {
	    print $fh "--- \n";
	    {
		open IN, "$FindBin::RealBin/testdata/$document"
		    or die $!;
		local $/ = undef;
		print $fh <IN>;
		close IN;
	    }
	}

	$combined_document{$newname} = $outfile;
	close $fh;
    }
}

push @yaml_syck_defs, (
		       [$combined_document{"invalid_schema"}, "document05a.yaml", 0],
		       ["schema05.yaml", $combined_document{"invalid_diff"}, 0],
		       ["schema05.yaml", $combined_document{"valid_same"}, 1],
		       ["schema05.yaml", $combined_document{"invalid_same"}, 0],
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
	if (!File::Spec->file_name_is_absolute($_)) {
	    $_ = "$FindBin::RealBin/testdata/$_";
	}
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
    is($valid, $expect_validity, "@cmd")
	or diag("@cmd");
}

__END__
