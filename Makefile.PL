use 5.000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Kwalify',
    VERSION_FROM      => 'lib/Kwalify.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Kwalify.pm', # retrieve abstract from module
       AUTHOR         => 'Slaven Rezic <srezic@cpan.org>') : ()),
);
