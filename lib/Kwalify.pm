# -*- perl -*-

#
# $Id: Kwalify.pm,v 1.10 2006/11/28 23:04:04 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2006 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: srezic@cpan.org
# WWW:  http://www.rezic.de/eserte/
#

package Kwalify;

use strict;

use base qw(Exporter);
use vars qw(@EXPORT_OK $VERSION);
@EXPORT_OK = qw(validate);

$VERSION = sprintf("%d.%02d", q$Revision: 1.10 $ =~ /(\d+)\.(\d+)/);

BEGIN {
    if ($] < 5.006) {
	$INC{"warnings.pm"} = 1;
	*warnings::import = sub { };
	*warnings::unimport = sub { };
    }
}

sub validate ($$) {
    my($schema, $data) = @_;
    my $self = Kwalify::Validator->new;
    $self->validate($schema, $data, "/");
    if (@{$self->{errors}}) {
	die join("\n", map { "  - $_" } @{$self->{errors}}) . "\n";
    } else {
	1;
    }
}

package Kwalify::Validator;

use overload ();

sub new {
    my($class) = @_;
    bless { errors => [] }, $class;
}

sub validate {
    my($self, $schema, $data, $path, $args) = @_;
    $self->{done} = {};
    $self->_validate($schema, $data, $path, $args);
}

sub _validate {
    my($self, $schema, $data, $path, $args) = @_;
    $self->{path} = $path;

    if (!UNIVERSAL::isa($schema, "HASH")) {
	$self->_die("Schema structure must be a hash reference");
    }

    my $type = $schema->{type};
    if (!defined $type) {
	$type = 'str'; # default type;
    }
    my $type_check_method = "validate_" . $type;
    if (!$self->can($type_check_method)) {
	$self->_die("Invalid or unimplemented type `$type'");
    }

    $self->$type_check_method($schema, $data, $path, $args);
}

sub _additional_rules {
    my($self, $schema, $data, $path) = @_;
    if (defined $schema->{pattern}) {
	(my $pattern = $schema->{pattern}) =~ s{^/(.*)/$}{$1};
	if ($data !~ qr{$pattern}) {
	    $self->_error("Non-valid data `$data' does not match /$pattern/");
	}
    }
    if (defined $schema->{'length'}) {
	if (!UNIVERSAL::isa($schema->{'length'}, "HASH")) {
	    $self->_die("`length' must be a hash with keys max and/or min");
	}
	my $length = length($data);
	if (exists $schema->{'length'}->{min}) {
	    my $min = $schema->{'length'}->{min};
	    if ($length < $min) {
		$self->_error("`$data' is too short (length $length < min $min)");
	    }
	}
	if (exists $schema->{'length'}->{'min-ex'}) {
	    my $min = $schema->{'length'}->{'min-ex'};
	    if ($length <= $min) {
		$self->_error("`$data' is too short (length $length <= min $min)");
	    }
	}
	if (exists $schema->{'length'}->{max}) {
	    my $max = $schema->{'length'}->{max};
	    if ($length > $max) {
		$self->_error("`$data' is too long (length $length > max $max)");
	    }
	}
	if (exists $schema->{'length'}->{'max-ex'}) {
	    my $max = $schema->{'length'}->{'max-ex'};
	    if ($length > $max) {
		$self->_error("`$data' is too long (length $length >= max $max)");
	    }
	}
    }
    if (defined $schema->{enum}) {
	if (!UNIVERSAL::isa($schema->{enum}, 'ARRAY')) {
	    $self->_die("`enum' must be an array");
	}
	my %valid = map { ($_,1) } @{ $schema->{enum} };
	if (!exists $valid{$data}) {
	    $self->_error("`$data': invalid " . _base_path($path) . " value");
	}
    }
    if (defined $schema->{range}) {
	if (!UNIVERSAL::isa($schema->{range}, "HASH")) {
	    $self->_die("`range' must be a hash with keys max and/or min");
	}
 	my($lt, $le, $gt, $ge);
## yes? no?
# 	if (eval { require Scalar::Util; defined &Scalar::Util::looks_like_number }) {
# 	    if (Scalar::Util::looks_like_number($data)) {
# 		$lt = sub { $_[0] < $_[1] };
# 		$gt = sub { $_[0] > $_[1] };
# 	    } else {
# 		$lt = sub { $_[0] lt $_[1] };
# 		$gt = sub { $_[0] gt $_[1] };
# 	    }
# 	} else {
#	    warn "Cannot determine whether $data is a number, assume so..."; # XXX show only once
	    no warnings 'numeric';
	    $lt = sub { $_[0] < $_[1] };
	    $gt = sub { $_[0] > $_[1] };
	    $le = sub { $_[0] <= $_[1] };
	    $ge = sub { $_[0] >= $_[1] };
#	}
	    
	if (exists $schema->{range}->{min}) {
	    my $min = $schema->{range}->{min};
	    if ($lt->($data, $min)) {
		$self->_error("`$data' is too small (< min $min)");
	    }
	}
	if (exists $schema->{range}->{'min-ex'}) {
	    my $min = $schema->{range}->{'min-ex'};
	    if ($le->($data, $min)) {
		$self->_error("`$data' is too small (<= min $min)");
	    }
	}
	if (exists $schema->{range}->{max}) {
	    my $max = $schema->{range}->{max};
	    if ($gt->($data, $max)) {
		$self->_error("`$data' is too large (> max $max)");
	    }
	}
	if (exists $schema->{range}->{'max-ex'}) {
	    my $max = $schema->{range}->{'max-ex'};
	    if ($ge->($data, $max)) {
		$self->_error("`$data' is too large (>= max $max)");
	    }
	}
    }
    if (defined $schema->{assert}) {
	$self->_die("`assert' is not yet implemented");
    }
}

sub validate_text {
    my($self, $schema, $data, $path) = @_;
    if (!defined $data || ref $data) {
	return $self->_error("Non-valid data `" . (defined $data ? $data : 'undef') . "', expected text");
    }
    $self->_additional_rules($schema, $data, $path);
}

sub validate_str {
    my($self, $schema, $data, $path) = @_;
    if (!defined $data || ref $data || $data =~ m{^\d+(\.\d+)?$}) {
	return $self->_error("Non-valid data `" . (defined $data ? $data : 'undef') . "', expected a str");
    }
    $self->_additional_rules($schema, $data, $path);
}

sub validate_int {
    my($self, $schema, $data, $path) = @_;
    if ($data !~ m{^[+-]?\d+$}) { # XXX what about scientific notation?
	$self->_error("Non-valid data `" . $data . "', expected an int");
    }
    $self->_additional_rules($schema, $data, $path);
}

sub validate_float {
    my($self, $schema, $data, $path) = @_;
    if ($data !~ m{^[+-]?\d+\.\d+$}) { # XXX other values?
	$self->_error("Non-valid data `" . $data . "', expected a float");
    }
    $self->_additional_rules($schema, $data, $path);
}

sub validate_number {
    my($self, $schema, $data, $path) = @_;
    if ($data !~ m{^[+-]?\d+(\.\d+)?$}) { # XXX combine int+float regexp!
	$self->_error("Non-valid data `" . $data . "', expected a number");
    }
    $self->_additional_rules($schema, $data, $path);
}

sub validate_bool {
    my($self, $schema, $data, $path) = @_;
    if ($data !~ m{^(yes|true|1|no|false|0)$}) { # XXX correct?
	$self->_error("Non-valid data `" . $data . "', expected a boolean");
    }
    $self->_additional_rules($schema, $data, $path);
}

# XXX is this correct?
sub validate_scalar {
    shift->validate_text(@_);
}

sub validate_date {
    my($self, $schema, $data, $path) = @_;
    if ($data !~ m{^\d{4}-\d{2}-\d{2}$}) {
	$self->_error("Non-valid data `" . $data . "', expected a date (YYYY-MM-DD)");
    }
    $self->_additional_rules($schema, $data, $path);
}

sub validate_time {
    my($self, $schema, $data, $path) = @_;
    if ($data !~ m{^\d{2}:\d{2}:\d{2}$}) {
	$self->_error("Non-valid data `" . $data . "', expected a time (HH:MM:SS)");
    }
    $self->_additional_rules($schema, $data, $path);
}

sub validate_timestamp {
    my($self) = @_;
    $self->_error("timestamp validation NYI"); # XXX
}

sub validate_any {
    1;
}

sub validate_seq {
    my($self, $schema, $data, $path) = @_;
    if (!exists $schema->{sequence}) {
	$self->_die("`sequence' missing with `seq' type");
    }
    my $sequence = $schema->{sequence};
    if (!UNIVERSAL::isa($sequence, 'ARRAY')) {
	$self->_die("Expected array in `sequence'");
    }
    if (@$sequence != 1) {
	$self->_die("Expect exactly one element in sequence");
    }
    if (!UNIVERSAL::isa($data, 'ARRAY')) {
	$self->_error("Non-valid data " . $data . ", expected sequence");
	return;
    }

    return if ($self->{done}{overload::StrVal($data)}{overload::StrVal($schema)});
    $self->{done}{overload::StrVal($data)}{overload::StrVal($schema)} = 1;

    my $subschema = $sequence->[0];
    my $unique = _get_boolean($subschema->{unique});
    my %unique_val;
    my %unique_mapping_val;
    my $index = 0;
    for my $elem (@$data) {
	my $subpath = _append_path($path, $index);
	$self->_validate($subschema, $elem, $subpath, { unique_mapping_val => \%unique_mapping_val});
	if ($unique) {
	    if (exists $unique_val{$elem}) {
		$self->_error("`$elem' is already used at `$unique_val{$elem}'");
	    } else {
		$unique_val{$elem} = $subpath;
	    }
	}
	$index++;
    }
}

sub validate_map {
    my($self, $schema, $data, $path, $args) = @_;
    my $unique_mapping_val;
    if ($args && $args->{unique_mapping_val}) {
	$unique_mapping_val = $args->{unique_mapping_val};
    }
    if (!exists $schema->{mapping}) {
	$self->_die("`mapping' missing with `map' type");
    }
    my $mapping = $schema->{mapping};
    if (!UNIVERSAL::isa($mapping, 'HASH')) {
	$self->_die("Expected hash in `mapping'");
    }
    if (!UNIVERSAL::isa($data, 'HASH')) {
	$self->_error("Non-valid data " . $data . ", expected mapping");
    }

    return if ($self->{done}{overload::StrVal($data)}{overload::StrVal($schema)});
    $self->{done}{overload::StrVal($data)}{overload::StrVal($schema)} = 1;

    my %seen_key;
    my $default_key_schema;

    ## Originally this was an each-loop, but this could lead into
    ## endless recursions, because mapping may be reused in Kwalify,
    ## thus the each iterator was shared between recursion levels.
    # while(my($key,$subschema) = each %$mapping) {
    for my $key (keys %$mapping) {
	my $subschema = $mapping->{$key};
	if ($key eq '=') { # the "default" key
	    $default_key_schema = $subschema;
	    next;
	}
	my $subpath = _append_path($path, $key);
	$self->{path} = $subpath;
	if (!UNIVERSAL::isa($subschema, 'HASH')) {
	    $self->_die("Expected subschema (a hash)");
	}
	my $required = _get_boolean($subschema->{required});
	if (!exists $data->{$key}) {
	    if ($required) {
		$self->{path} = $path;
		$self->_error("Expected required key `$key'");
		next;
	    } else {
		next;
	    }
	}
	my $unique = _get_boolean($subschema->{unique});
	if ($unique) {
	    if (defined $unique_mapping_val->{$key}->{val} && $unique_mapping_val->{$key}->{val} eq $data->{$key}) {
		$self->_error("`$data->{$key}' is already used at `$unique_mapping_val->{$key}->{path}'");
	    } else {
		$unique_mapping_val->{$key} = { val  => $data->{$key},
						path => $subpath,
					      };
	    }
	}

	$self->_validate($subschema, $data->{$key}, $subpath);
	$seen_key{$key}++;
    }

#    while(my($key,$val) = each %$data) {
    for my $key (keys %$data) {
	my $val = $data->{$key};
	my $subpath = _append_path($path, $key);
	$self->{path} = $subpath;
	if (!$seen_key{$key}) {
	    if ($default_key_schema) {
		$self->_validate($default_key_schema, $val, $subpath);
	    } else {
		$self->_error("Unexpected key `$key'");
	    }
	}
    }
}

sub _die {
    my($self, $msg) = @_;
    $msg = "[$self->{path}] $msg";
    die $msg."\n";
}

sub _error {
    my($self, $msg) = @_;
    $msg = "[$self->{path}] $msg";
    push @{$self->{errors}}, $msg;
    0;
}

# Functions:
sub _append_path {
    my($root, $leaf) = @_;
    $root . ($root !~ m{/$} ? "/" : "") . $leaf;
}

sub _base_path {
    my($path) = @_;
    my($base) = $path =~ m{([^/]+)$};
    $base;
}

sub _get_boolean {
    my($val) = @_;
    defined $val && $val =~ m{^(yes|true|1)$}; # XXX check for all boolean trues
}

1;
__END__

=encoding iso-8859-2

=head1 NAME

Kwalify - Kwalify schema for data structures

=head1 SYNOPSIS

  use Kwalify qw(validate);
  validate($schema, $data);

Typically used together with YAML or JSON:

  use YAML;
  validate(YAML::LoadFile($schema_file), YAML::LoadFile($data_file));

  use JSON;
  validate(jsonToObj($schema_data), jsonToObj($data));

=head1 DESCRIPTION

=head2 validate($schema_data, $data)

Validate I<$data> according to Kwalify schema specified in
I<$schema_data>. Dies if the validation fails.

B<validate> may be exported.

=head1 AUTHOR

Slaven Reziæ, E<lt>srezic@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Slaven Reziæ

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<pkwalify>, L<kwalify(1)>.

=cut
