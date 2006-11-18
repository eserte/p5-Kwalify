#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: Kwalify.t,v 1.4 2006/11/18 13:16:10 eserte Exp $
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

my $yaml_syck_tests;
BEGIN {
    $yaml_syck_tests = 34;
    plan tests => 1 + $yaml_syck_tests + 2;
}

BEGIN {
    use_ok('Kwalify', 'validate');
}

sub is_valid_yaml {
    my($schema, $document, $testname) = @_;
    local $Test::Builder::Level = $Test::Builder::Level+1;
    ok(validate(YAML::Syck::Load($schema), YAML::Syck::Load($document)), $testname);
}

sub is_invalid_yaml {
    my($schema, $document, $errors, $testname) = @_;
    local $Test::Builder::Level = $Test::Builder::Level+1;
    ok(!eval { validate(YAML::Syck::Load($schema), YAML::Syck::Load($document)) }, $testname);
    for my $error (@$errors) {
	if (UNIVERSAL::isa($error, 'HASH')) {
	    my($pattern, $testname) = @{$error}{qw(pattern testname)};
	    like($@, $pattern, $testname);
	} else {
	    like($@, $error);
	}
    }
}

SKIP: {
    skip("Need YAML::Syck for tests", $yaml_syck_tests)
	if !eval { require YAML::Syck; 1 };

    my $schema01 = <<'EOF';
type:   seq
sequence:
  - type:   str
EOF
    my $document01a = <<'EOF';
- foo
- bar
- baz
EOF
    is_valid_yaml($schema01, $document01a, "sequence of str");

    my $schema01b = <<'EOF';
type:   seq
sequence: [{}]
EOF
    is_valid_yaml($schema01b, $document01a, "sequence with default type (str)");

    my $document01b = <<'EOF';
- foo
- 123
- baz
EOF

    is_invalid_yaml($schema01,$document01b, 
		    [qr{\Q[/1] Non-valid data `123', expected a str}],
		    "Non valid data, int in sequence of str");
    
    my $schema02 = <<'EOF';
type:       map
mapping:
  name:
    type:      str
    required:  yes
  email:
    type:      str
    pattern:   /@/
  age:
    type:      int
  birth:
    type:      date
EOF

    my $document02a = <<'EOF';
name:   foo
email:  foo@mail.com
age:    20
birth:  1985-01-01
EOF
    is_valid_yaml($schema02, $document02a, "mapping");

    my $document02b = <<'EOF';
name:   foo
email:  foo(at)mail.com
age:    twenty
birth:  Jun 01, 1985
EOF
    is_invalid_yaml($schema02, $document02b,
		    [qr{\Q[/birth] Non-valid data `Jun 01, 1985', expected a date (YYYY-MM-DD)},
		     qr{\Q[/age] Non-valid data `twenty', expected an int},
		     qr{\Q[/email] Non-valid data `foo(at)mail.com' does not match /@/},
		    ],
		    "invalid mapping");

    my $schema03 = <<'EOF';
type:      seq
sequence:
  - type:      map
    mapping:
      name:
        type:      str
        required:  true
      email:
        type:      str
EOF
    my $document03a = <<'EOF';
- name:   foo
  email:  foo@mail.com
- name:   bar
  email:  bar@mail.net
- name:   baz
  email:  baz@mail.org
EOF
    is_valid_yaml($schema03, $document03a, "sequence of mapping");
    my $document03b = <<'EOF';
- name:   foo
  email:  foo@mail.com
- naem:   bar
  email:  bar@mail.net
- name:   baz
  mail:   baz@mail.org
EOF
    is_invalid_yaml($schema03, $document03b,
		    [qr{\Q[/1] Expected required key `name'},
		     qr{\Q[/1/naem] Unexpected key `naem'},
		     qr{\Q[/2/mail] Unexpected key `mail'},
		    ]);

    my $schema04 = <<'EOF';
type:      map
mapping:
  company:
    type:      str
    required:  yes
  email:
    type:      str
  employees:
    type:      seq
    sequence:
      - type:    map
        mapping:
          code:
            type:      int
            required:  yes
          name:
            type:      str
            required:  yes
          email:
            type:      str
EOF
    my $document04a = <<'EOF';
company:    Kuwata lab.
email:      webmaster@kuwata-lab.com
employees:
  - code:   101
    name:   foo
    email:  foo@kuwata-lab.com
  - code:   102
    name:   bar
    email:  bar@kuwata-lab.com
EOF
    is_valid_yaml($schema04, $document04a, "mapping of sequence");
    my $document04b = <<'EOF';
company:    Kuwata Lab.
email:      webmaster@kuwata-lab.com
employees:
  - code:   A101
    name:   foo
    email:  foo@kuwata-lab.com
  - code:   102
    name:   bar
    mail:   bar@kuwata-lab.com
EOF
    is_invalid_yaml($schema04, $document04b,
		    [qr{\Q[/employees/0/code] Non-valid data `A101', expected an int},
		     qr{\Q[/employees/1/mail] Unexpected key `mail'},
		    ]);

    my $schema05 = <<'EOF';
type:      seq                                # new rule
sequence:
  -
    type:      map                            # new rule
    mapping:
      name:
        type:       str                       # new rule
        required:   yes
      email:
        type:       str                       # new rule
        required:   yes
        pattern:    /@/
      password:
        type:       text                      # new rule
        length:     { max: 16, min: 8 }
      age:
        type:       int                       # new rule
        range:      { max: 30, min: 18 }
        # or assert: 18 <= val && val <= 30
      blood:
        type:       str                       # new rule
        enum:
          - A
          - B
          - O
          - AB
      birth:
        type:       date                      # new rule
      memo:
        type:       any                       # new rule
EOF
    my $document05a = <<'EOF';
- name:     foo
  email:    foo@mail.com
  password: xxx123456
  age:      20
  blood:    A
  birth:    1985-01-01
- name:     bar
  email:    bar@mail.net
  age:      25
  blood:    AB
  birth:    1980-01-01
EOF
    is_valid_yaml($schema05, $document05a, "Many rules");
    my $document05b = <<'EOF';
- name:     foo
  email:    foo(at)mail.com
  password: xxx123
  age:      twenty
  blood:    a
  birth:    1985-01-01
- given-name:  bar
  family-name: Bar
  email:    bar@mail.net
  age:      15
  blood:    AB
  birth:    1980/01/01
EOF
    is_invalid_yaml($schema05, $document05b,
		    [
		     qr{\Q[/0/blood] `a': invalid blood value},
		     qr{\Q[/0/email] Non-valid data `foo(at)mail.com' does not match /@/},
		     qr{\Q[/0/password] `xxx123' is too short (length 6 < min 8)},
		     qr{\Q[/0/age] Non-valid data `twenty', expected an int},
		     qr{\Q[/0/age] `twenty' is too small (< min 18)},
		     qr{\Q[/1/birth] Non-valid data `1980/01/01', expected a date (YYYY-MM-DD)},
		     qr{\Q[/1] Expected required key `name'},
		     qr{\Q[/1/age] `15' is too small (< min 18)},
		     qr{\Q[/1/given-name] Unexpected key `given-name'},
		     qr{\Q[/1/family-name] Unexpected key `family-name'},
		    ]);

    my $schema06 = <<'EOF';
type: seq
sequence:
  - type:     map
    required: yes
    mapping:
      name:
        type:     str
        required: yes
        unique:   yes
      email:
        type:     str
      groups:
        type:     seq
        sequence:
          - type: str
            unique:   yes
EOF
    my $document06a = <<'EOF';
- name:   foo
  email:  admin@mail.com
  groups:
    - users
    - foo
    - admin
- name:   bar
  email:  admin@mail.com
  groups:
    - users
    - admin
- name:   baz
  email:  baz@mail.com
  groups:
    - users
EOF
    is_valid_yaml($schema06, $document06a, "unique");
    my $document06b = <<'EOF';
- name:   foo
  email:  admin@mail.com
  groups:
    - foo
    - users
    - admin
    - foo
- name:   bar
  email:  admin@mail.com
  groups:
    - admin
    - users
- name:   bar
  email:  baz@mail.com
  groups:
    - users
EOF
    is_invalid_yaml($schema06, $document06b,
		    [qr{\Q[/0/groups/3] `foo' is already used at `/0/groups/0'},
		     qr{\Q[/2/name] `bar' is already used at `/1/name'},
		    ]);

}

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

    ok(validate($schema06_pl, $document06a_pl), "valid data against perl schema");
    eval { validate($schema06_pl, $document06b_pl) };
    ok($@, "invalid data against perl schema");
}

__END__
