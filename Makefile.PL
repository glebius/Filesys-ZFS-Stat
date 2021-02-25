use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Filesys::ZFS::Stat',
    AUTHOR           => q{Gleb Smirnoff <glebius@FreeBSD.org>},
    VERSION_FROM     => 'lib/Filesys/ZFS/Stat.pm',
    ABSTRACT_FROM    => 'lib/Filesys/ZFS/Stat.pm',
    LICENSE          => 'BSD',
    MIN_PERL_VERSION => '5.006',
    PREREQ_PM => {
        'BSD::Sysctl' => '0.12',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Filesys-ZFS-Stat-*' },
);
