#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: pkwalify.t,v 1.7 2006/12/02 10:03:18 eserte Exp $
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

my $tests_per_case = 3;
plan tests => 1 + $tests_per_case*(scalar(@yaml_syck_defs) + scalar(@json_defs));

my $script = "$FindBin::RealBin/../blib/script/pkwalify";
my @cmd = ($^X, "-Mblib=$FindBin::RealBin/..", $script, "-s");

SKIP: {
    skip("Need YAML::Syck for tests", $tests_per_case*scalar(@yaml_syck_defs))
	if !eval { require YAML::Syck; 1 };

    for my $def (@yaml_syck_defs) {
	any_test($def);
    }
}

SKIP: {
    skip("Need JSON for tests", $tests_per_case*scalar(@json_defs))
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
	    diag "STDOUT=$stdout\nSTDERR=$stderr\n" if $v;
	} else {
	    $valid = 1;
	}
	if ($valid) {
	    is($stdout, "", "No warnings in @cmd");
	} else {
	    isnt($stdout, "", "There are warnings in @cmd");
	}
	is($stderr, "", "Nothing in STDERR");
    } elsif (eval { require IPC::Open3; 1 }) {
	*OLDOUT = *OLDOUT; # cease -w
	*OLDERR = *OLDERR; # cease -w
	open(OLDOUT, ">&STDOUT") or die $!;
	open(OLDERR, ">&STDERR") or die $!;
	open(STDOUT, ">".File::Spec->devnull) or die $!;
	open(STDERR, ">".File::Spec->devnull) or die $!;
	system(@cmd);
	close STDERR;
	close STDOUT;
	open(STDERR, ">&OLDERR") or die $!;
	open(STDOUT, ">&OLDOUT") or die $!;

	$valid = $? == 0 ? 1 : 0;
    SKIP: { skip("No stdout/stderr tests without IPC::Run", 2) }
    }
    is($valid, $expect_validity, "@cmd")
	or diag("@cmd");
}

# Should be last because of STDERR redirection
{
    open(STDERR, ">" . File::Spec->devnull);
    system($^X, "-c", "-Mblib=$FindBin::RealBin/..", $script);
    ok($?==0, "$script compiles OK");
}

__END__
