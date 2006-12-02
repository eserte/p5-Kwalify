#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: compat.t,v 1.1 2006/12/02 10:45:04 eserte Exp $
# Author: Slaven Rezic
#

use strict;
use Kwalify qw(validate);
use Test;

plan tests => 2;

{
    my $schema06_pl =
	{
	 'sequence' => [
			{
			 'mapping' => {
				       'email' => {
						   'type' => 'str'
						  },
				       'groups' => {
						    'sequence' => [
								   {
								    'unique' => 'yes',
								    'type' => 'str'
								   }
								  ],
						    'type' => 'seq'
						   },
				       'name' => {
						  'unique' => 'yes',
						  'required' => 'yes',
						  'type' => 'str'
						 }
				      },
			 'required' => 'yes',
			 'type' => 'map'
			}
		       ],
	 'type' => 'seq'
	};

    my $document06a_pl =
	[
	 {
	  'email' => 'admin@mail.com',
	  'groups' => [
		       'users',
		       'foo',
		       'admin'
		      ],
	  'name' => 'foo'
	 },
	 {
	  'email' => 'admin@mail.com',
	  'groups' => [
		       'users',
		       'admin'
		      ],
	  'name' => 'bar'
	 },
	 {
	  'email' => 'baz@mail.com',
	  'groups' => [
		       'users'
		      ],
	  'name' => 'baz'
	 }
	];

    my $document06b_pl =
	[
	 {
	  'email' => 'admin@mail.com',
	  'groups' => [
		       'foo',
		       'users',
		       'admin',
		       'foo'
		      ],
	  'name' => 'foo'
	 },
	 {
	  'email' => 'admin@mail.com',
	  'groups' => [
		       'admin',
		       'users'
		      ],
	  'name' => 'bar'
	 },
	 {
	  'email' => 'baz@mail.com',
	  'groups' => [
		       'users'
		      ],
	  'name' => 'bar'
	 }
	];

    ok(validate($schema06_pl, $document06a_pl));
    eval { validate($schema06_pl, $document06b_pl) };
    ok($@);
}


__END__
