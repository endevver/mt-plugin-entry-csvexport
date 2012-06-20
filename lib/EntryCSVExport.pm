package EntryCSVExport;

use strict;
use warnings;
use Regexp::List;
use Carp qw( croak );
use base qw(  Class::Accessor::Fast  );

__PACKAGE__->mk_accessors(qw(
    object_type
    buffer
    iterator
    model
    csv
));

sub validate_parameters {
    my $self = shift;

    for (qw( object_type iterator )) {
        croak "$_ property not defined for EntryCSVExport object"
            unless defined $self->$_;
    }

    unless ( $self->buffer ) {
        require IO::String;
        $self->buffer( IO::String->new );
    }

    unless ( defined $self->csv ) {
        require Text::CSV;
        $self->csv( Text::CSV->new( { binary => 1, eol => "\n" } ) );
    }
}

sub generate {
    my $self = shift;

    $self->validate_parameters();

    my $iterator = $self->iterator;
    my $buffer   = $self->buffer;
    my $csv      = $self->csv;

    require EntryCSVExport::Data;
    my $data = EntryCSVExport::Data->new({
        object_type => $self->object_type,
        model       => $self->model,
    });

    $csv->print( $buffer, $data->column_headers );

    while ( my $e = $iterator->() ) {
        $csv->print( $buffer, $data->row_values($e) );
    }

    return $buffer->string_ref if 'IO::String' eq ref($buffer);
    return $buffer;
}

1;

__END__

