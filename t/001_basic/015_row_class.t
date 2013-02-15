use t::Utils;
use Mock::Basic;
use Test::More;

{
    package Mock::BasicRow;
    use base qw(Iroh);

    sub setup_test_db {
        shift->do(q{
            CREATE TABLE mock_basic_row (
                id   INT,
                name TEXT
            )
        });
    }

    package Mock::BasicRow::Schema;
    use utf8;
    use Iroh::Schema::Declare;

    table {
        name 'mock_basic_row';
        pk 'id';
        columns qw/
            id
            name
        /;
    };

    table {
        name 'mock_basic_row_foo';
        pk 'id';
        columns qw/
            id
            name
        /;
        row_class 'Mock::BasicRow::FooRow';
    };

    package Mock::BasicRow::FooRow;
    use strict;
    use warnings;
    use base 'Iroh::Row';

    package Mock::BasicRow::Row::MockBasicRow;
    use strict;
    use warnings;
    use base 'Iroh::Row';

    sub foo {
        'foo'
    }
}

my $dbh = t::Utils->setup_dbh;
my $db_basic = Mock::Basic->new({dbh => $dbh});
   $db_basic->setup_test_db;
   $db_basic->insert('mock_basic',{
        id   => 1,
        name => 'perl',
   });

my $db_basic_row = Mock::BasicRow->new({
    connect_info => ['dbi:SQLite::memory:'],
});
$db_basic_row->setup_test_db;
$db_basic_row->insert('mock_basic_row',{
    id   => 1,
    name => 'perl',
});

subtest 'no your row class' => sub {
    my $row = $db_basic->single('mock_basic',{id => 1});
    isa_ok $row, 'Iroh::Row';
};

subtest 'your row class' => sub {
    my $row = $db_basic_row->single('mock_basic_row',{id => 1});
    isa_ok $row, 'Mock::BasicRow::Row::MockBasicRow';
    is $row->foo, 'foo';
    is $row->id, 1;
    is $row->name, 'perl';
};

subtest 'row_class specific Schema.pm' => sub {
    is +$db_basic_row->schema->get_row_class('mock_basic_row_foo'), 'Mock::BasicRow::FooRow';
};

subtest 'handle' => sub {
    my $row = $db_basic->single('mock_basic',{id => 1});
    isa_ok $row->handle, 'Mock::Basic';
    can_ok $row->handle, 'single';
};

subtest 'your row class AUTOLOAD' => sub {
    my $row = $db_basic_row->single('mock_basic_row',{id => 1},{'+columns' => [\'id+10 as id_plus_ten']});
    isa_ok $row, 'Mock::BasicRow::Row::MockBasicRow';
    is $row->foo, 'foo';
    is $row->id, 1;
    is $row->name, 'perl';
    is $row->id_plus_ten, 11;

    ok $row->can('id');
    ok ! $row->can('mock_basic_id');
};

subtest 'AUTOLOAD' => sub {
    my $row = $db_basic->search_by_sql(q{select id as mock_basic_id from mock_basic where id = 1})->next;
    isa_ok $row, 'Iroh::Row';
    is $row->mock_basic_id, 1;
    ok ! $row->can('mock_basic_id');
};

subtest 'can not use (update|delete) method' => sub {
    $db_basic->do('create table test_db (id integer)');
    $db_basic->do('insert into test_db (id) values (1)');
    my $row = $db_basic->search_by_sql(q{select id from test_db where id = 1})->next;
    isa_ok $row, 'Iroh::Row';
    is $row->id, 1;
    eval {
        $row->update;
    };
    like $@, qr/can't update from basic Iroh::Row class./;
    $@ = undef;
    eval {
        $row->delete;
    };
    like $@, qr/can't delete from basic Iroh::Row class./;
    $db_basic->do('drop table test_db');
};

done_testing;

