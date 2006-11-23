# -*- perl -*-

#
# $Id: Kwalify.pm,v 1.1 2006/11/23 20:55:34 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2006 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package Schema::Kwalify;

use strict;
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

use Kwalify qw();

sub new {
    bless {}, shift;
}

sub validate {
    my($self, $schema, $data) = @_;
    Kwalify::kwalify($schema, $data);
}

1;

__END__
