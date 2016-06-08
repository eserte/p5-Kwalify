#!/usr/bin/perl

# Source: http://yaml.org/type/float.html

use strict;
use warnings;

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

SKIP: {
    skip("Need YAML::Syck for tests", 6)
        if !eval { require YAML::Syck; 1 };

    my $schema = <<'EOF';
type:       map
mapping:
  earnings:
    type:      float
EOF

    my $document01 = <<'EOF';
earnings:    6.8523015e+5
EOF

    my $document02 = <<'EOF';
earnings:    685.230_15e+03
EOF

    my $document03 = <<'EOF';
earnings:    685_230.15
EOF

    my $document04 = <<'EOF';
earnings:    190:20:30.15
EOF

    my $document05 = <<'EOF';
earnings:    -.inf
EOF

    my $document06 = <<'EOF';
earnings:    .NaN
EOF

    ok(validate(YAML::Syck::Load($schema), YAML::Syck::Load($document01)), 'Canonical');
    ok(validate(YAML::Syck::Load($schema), YAML::Syck::Load($document02)), 'Exponential');
    ok(validate(YAML::Syck::Load($schema), YAML::Syck::Load($document03)), 'Fixed');
    ok(validate(YAML::Syck::Load($schema), YAML::Syck::Load($document04)), 'Sexagesimal');
    ok(validate(YAML::Syck::Load($schema), YAML::Syck::Load($document05)), 'Negative infinity');
    ok(validate(YAML::Syck::Load($schema), YAML::Syck::Load($document06)), 'Not a number');
}

done_testing();
