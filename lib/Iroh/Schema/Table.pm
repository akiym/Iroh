package Iroh::Schema::Table;
use strict;
use warnings;
use Class::Accessor::Lite
    rw => [ qw(
        name
        primary_keys
        columns
        escaped_columns
        sql_types
        row_class
        base_row_class
    ) ]
;
use Carp ();
use Class::Load ();

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        escaped_columns => {},
        base_row_class  => 'Iroh::Row',
        %args
    }, $class;

    # load row class
    my $row_class = $self->row_class;
    Class::Load::load_optional_class($row_class) or do {
        # make row class automatically
        Class::Load::load_class($self->base_row_class);
        no strict 'refs'; @{"$row_class\::ISA"} = ($self->base_row_class);
    };
    for my $col (@{$self->columns}) {
        no strict 'refs';
        unless ($row_class->can($col)) {
            *{"$row_class\::$col"} = $row_class->generate_column_accessor($col);
        }
    }
    $self->row_class($row_class);

    return $self;
}

sub get_sql_type {
    my ($self, $column_name) = @_;
    $self->sql_types->{ $column_name };
}

sub prepare_from_dbh {
    my ($self, $dbh) = @_;

    $self->escaped_columns->{$dbh->{Driver}->{Name}} ||= [
        map { \$dbh->quote_identifier($_) }
        @{$self->columns}
    ];
}

1;

__END__

=head1 NAME

Iroh::Schema::Table - Iroh table class.

=head1 METHODS

=over 4

=item $table = Iroh::Schema::Table->new

create new Iroh::Schema::Table's object.

=item $table->get_sql_type

get column SQL type.

=back
