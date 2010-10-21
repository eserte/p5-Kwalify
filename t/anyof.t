#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#

use strict;

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "1..0 # skip: no Test::More module\n";
	exit;
    }
}

use Kwalify;

plan tests => 6;

{
    my $schema = { type => 'any',
		   of   => 'wrong',
		 };
    my $data = "foo";
    eval { Kwalify::validate($schema, $data) };
    like $@, qr{any of expects a sequence};
}

{
    my $schema = { type => 'any',
		   of   => [],
		 };
    my $data = "foo";
    eval { Kwalify::validate($schema, $data) };
    like $@, qr{any of sequence cannot be empty};
}

{
    my $schema = { type => 'any',
		   of   => [
			    { type => 'str' },
			    { type => 'seq', sequence => [{ type => 'any' }] },
			   ],
		 };
    {
	my $data = "foo";
	ok Kwalify::validate($schema, $data);
    }
    {
	my $data = ["foo"];
	ok Kwalify::validate($schema, $data);
    }
    {
	my $data = {"foo" => "bla"};
	ok !eval { Kwalify::validate($schema, $data) };
	like $@, qr{No any of subschema matched};
    }
}

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# End:
# vim:ft=perl:et:sw=4
