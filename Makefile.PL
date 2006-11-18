use 5.000;
use ExtUtils::MakeMaker;

$is_devel_host = defined $ENV{USER} && $ENV{USER} eq 'eserte' && $^O =~ /bsd/i && -f "../../perl.release.mk";

WriteMakefile(
    NAME              => 'Kwalify',
    VERSION_FROM      => 'lib/Kwalify.pm',
    PREREQ_PM         => {},
    EXE_FILES         => ['pkwalify'],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Kwalify.pm', # retrieve abstract from module
       AUTHOR         => 'Slaven Rezic <srezic@cpan.org>') : ()),
);

sub MY::postamble {
    my $postamble = '';

    if ($is_devel_host) {
	$postamble .= <<'EOF';

.include "../../perl.release.mk"
.include "../../perl.cvs.mk"

EOF
    }

    $postamble;
}
