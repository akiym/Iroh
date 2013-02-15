use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    license              => 'perl',
    dynamic_config       => 0,

    build_requires       => {
        'Test::More' => '0.98',
        'Test::Requires' => 0,
    },
    configure_requires   => { 'Module::Build' => '0.38' },
    requires             => {
        perl => '5.008005',
        'parent'                     => 0,
        'Carp'                       => 0,
        'Class::Accessor::Lite'      => '0.05',
        'Class::Load'                => '0.06',
        'Data::Page'                 => '2.02',
        'DBI'                        => '1.33',
        'DBIx::Inspector'            => '0.06',
        'DBIx::TransactionManager'   => '1.06',
        'SQL::Maker'                 => '0.14',
        'Data::Page::NoTotalEntries' => '0.02',
    },

    no_index    => { 'directory' => [ 'inc' ] },
    name        => 'Iroh',
    module_name => 'Iroh',

    # script_files => [''],

    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? 't/ xt/' : 't/',
    recursive_test_files => 1,

    create_readme  => 1,
    create_license => 1,
);
$build->create_build_script();
