#!/usr/bin/perl

# Source: http://yaml.org/type/int.html

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
    type:      int
EOF

    my $document01 = <<'EOF';
earnings:    685230
EOF

    my $document02 = <<'EOF';
earnings:    +685_230
EOF

    my $document03 = <<'EOF';
earnings:    02472256
EOF

    my $document04 = <<'EOF';
earnings:    0x_0A_74_AE
EOF

    my $document05 = <<'EOF';
earnings:    0b1010_0111_0100_1010_1110
EOF

    my $document06 = <<'EOF';
earnings:    190:20:30
EOF

    ok(validate(YAML::Syck::Load($schema), YAML::Syck::Load($document01)), 'Canonical');
    ok(validate(YAML::Syck::Load($schema), YAML::Syck::Load($document02)), 'Decimal');
    ok(validate(YAML::Syck::Load($schema), YAML::Syck::Load($document03)), 'Octal');
    ok(validate(YAML::Syck::Load($schema), YAML::Syck::Load($document04)), 'Hexadecimal');
    ok(validate(YAML::Syck::Load($schema), YAML::Syck::Load($document05)), 'Binary');
    ok(validate(YAML::Syck::Load($schema), YAML::Syck::Load($document06)), 'Sexagesimal');
}

done_testing();
