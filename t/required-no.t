#!/usr/bin/perl -w
# -*- cperl -*-

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

    if ($] < 5.005) {
	print "1..0 # skip: test works only with perl 5.005 or better\n";
	exit;
    }
}

use Kwalify qw(validate);

plan tests => 1;

# from https://github.com/eserte/p5-Kwalify/issues/1
# translated yaml to perl
my $schema = {
  'mapping' => {
    'foo' => {
      'mapping' => {
        'bar' => {
          'sequence' => [
            {
              'required' => 'no',
              'type' => 'str'
            }
          ],
          'required' => 'no',
          'type' => 'seq'
        }
      },
      'required' => 'yes',
      'type' => 'map'
    }
  },
  'desc' => 'test for tilde',
  'name' => 'test',
  'type' => 'map'
};

my $data = {
  'foo' => {
    'bar' => undef
  }
};

ok validate $schema, $data;

__END__
