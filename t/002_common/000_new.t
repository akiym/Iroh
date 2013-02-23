use t::Utils;
use Mock::Basic;
use Test::More;

for (qw/other main/) {
    unlink "./t/$_.db" if -f "./t/$_.db";
}

my $db = Mock::Basic->new(
    {
        connect_info => [
            'dbi:SQLite:./t/main.db',
            '',''
        ],
    }
);
$db->setup_test_db;
$db->insert('mock_basic',{
    id   => 1,
    name => 'perl',
});
$db->insert('mock_basic',{
    id   => 2,
    name => 'python',
});

subtest 'search' => sub {
    my @rows = $db->search('mock_basic',{id => 1});

    my $row = $rows[0];
    isa_ok $row, 'Iroh::Row';

    is $row->id, 1;
    is $row->name, 'perl';
};

subtest 'do new' => sub {
    my $model = Mock::Basic->new(
        {
            connect_info => [
                'dbi:SQLite:./t/main.db',
                '',
                '',
            ]
        }
    );
    my @rows = $model->search('mock_basic');

    my $row = $rows[0];
    isa_ok $row, 'Iroh::Row';

    is $row->id, 1;
    is $row->name, 'perl';
};

subtest 'do new other connection' => sub {
    my $model = Mock::Basic->new(
        {
            connect_info => [
                'dbi:SQLite:./t/other.db',
                '',
                '',
            ]
        }
    );
    $model->setup_test_db;
    $model->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });

    my @rows = $model->search('mock_basic');

    my $row = $rows[0];
    isa_ok $row, 'Iroh::Row';

    is $row->id, 1;
    is $row->name, 'perl';

    is +$db->count('mock_basic', 'id'), 2;
    is $model->count('mock_basic', 'id'), 1;
};

subtest 'do new with dbh' => sub {
    my $dbh = DBI->connect('dbi:SQLite::memory:', '', '')
        or die "cannot connect to t/main.db";
    my $model = Mock::Basic->new({
        dbh => $dbh,
    });
    $model->setup_test_db();
    $model->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });

    my @rows = $model->search('mock_basic');

    my $row = $rows[0];
    isa_ok $row, 'Iroh::Row';

    is $row->id, 1;
    is $row->name, 'perl';
};

unlink './t/other.db', './t/main.db';

done_testing;

