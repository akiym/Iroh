package Iroh::Schema::Declare;
use strict;
use warnings;
use parent qw(Exporter);
use Iroh::Schema;
use Iroh::Schema::Table;

our @EXPORT = qw(
    schema
    name
    table
    pk
    columns
    row_class
    base_row_class
);
our $CURRENT_SCHEMA_CLASS;

sub schema (&;$) { 
    my ($code, $schema_class) = @_;
    local $CURRENT_SCHEMA_CLASS = $schema_class;
    $code->();
    _current_schema();
}

sub base_row_class($) {
    my $current = _current_schema();
    $current->{__base_row_class} = $_[0];
}

sub row_namespace ($) {
    my $table_name = shift;

    (my $caller = caller(1)) =~ s/::Schema$//;
    join '::', $caller, 'Row', Iroh::Schema::camelize($table_name);
}

sub _current_schema {
    my $class = __PACKAGE__;
    my $schema_class;

    if ( $CURRENT_SCHEMA_CLASS ) {
        $schema_class = $CURRENT_SCHEMA_CLASS;
    } else {
        my $i = 1;
        while ( $schema_class = caller($i++) ) {
            if ( ! $schema_class->isa( $class ) ) {
                last;
            }
        }
    }

    if (! $schema_class) {
        Carp::confess( "PANIC: cannot find a package name that is not ISA $class" );
    }

    no warnings 'once';
    if (! $schema_class->isa( 'Iroh::Schema' ) ) {
        no strict 'refs';
        push @{ "$schema_class\::ISA" }, 'Iroh::Schema';
        my $schema = $schema_class->new();
        $schema_class->set_default_instance( $schema );
    }

    $schema_class->instance();
}

sub pk(@);
sub columns(@);
sub name ($);
sub row_class ($);
sub table(&) {
    my $code = shift;
    my $current = _current_schema();

    my (
        $table_name,
        @table_pk,
        @table_columns,
        $row_class,
    );
    no warnings 'redefine';
    
    my $dest_class = caller();
    no strict 'refs';
    no warnings 'once';
    local *{"$dest_class\::name"}      = sub ($) { 
        $table_name = shift;
        $row_class  = row_namespace($table_name);
    };
    local *{"$dest_class\::pk"}        = sub (@) { @table_pk = @_ };
    local *{"$dest_class\::columns"}   = sub (@) { @table_columns = @_ };
    local *{"$dest_class\::row_class"} = sub (@) { $row_class = shift };

    $code->();

    my @col_names;
    my %sql_types;
    while ( @table_columns ) {
        my $col_name = shift @table_columns;
        if (ref $col_name) {
            my $sql_type = $col_name->{type};
            $col_name = $col_name->{name};
            $sql_types{$col_name} = $sql_type;
        }
        push @col_names, $col_name;
    }

    $current->add_table(
        Iroh::Schema::Table->new(
            columns      => \@col_names,
            name         => $table_name,
            primary_keys => \@table_pk,
            sql_types    => \%sql_types,
            row_class    => $row_class,
            ($current->{__base_row_class} ? (base_row_class => $current->{__base_row_class}) : ()),
        )
    ); 
}

1;

__END__

=head1 NAME

Iroh::Schema::Declare - DSL For Declaring Iroh Schema

=head1 NORMAL USE

    package MyDB::Schema;
    use strict;
    use warnings;
    use Iroh::Schema::Declare;

    table {
        name    "your_table_name";
        pk      "primary_key";
        columns qw( col1 col2 col3 );
        row_class 'MyDB::Row'; # optional
    };

=head1 INLINE DECLARATION

    use Iroh::Schema::Declare;
    my $schema = schema {
        table {
            name "your_table_name";
            columns qw( col1 col2 col3 );
        };
    } "MyDB::Schema";

=head1 METHODS

=over 4

=item schema

schema data creation wrapper.

=item table

set table name

=item pk

set primary key

=item columns

set columns

=item row_namespace

create Row class namespace

=item base_row_class

Specify the default base row class with Iroh::Schema::Declare.

Default value is L<Iroh::Row>.

This option is useful when you adds features for My::DB::Row class.

=back

=cut

