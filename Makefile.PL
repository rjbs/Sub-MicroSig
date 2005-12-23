use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Sub::MicroSig',
    AUTHOR              => 'Ricardo Signes <rjbs@cpan.org>',
    VERSION_FROM        => 'lib/Sub/MicroSig.pm',
    ABSTRACT_FROM       => 'lib/Sub/MicroSig.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Sub-MicroSig-* cover_db' },
);
