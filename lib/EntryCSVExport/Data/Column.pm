package EntryCSVExport::Data::Column;

use strict;
use warnings;
use MT::Util qw( format_ts );

use base qw(  Class::Accessor::Fast  Class::Data::Inheritable  );

__PACKAGE__->mk_accessors(qw(
    key
    accessor
    date_time
    meta
));


sub label {
    my $self = shift;
    ( my $col = $self->key ) =~ s{^entry_}{};
    $col;
}

sub value {
    my $self = shift;
    my $e    = shift;
    my $key  = $self->key;

    # Get value for column, meta column or derived property.
    my $val = $self->is_meta()  ? $e->meta($key)
                                : $e->$key;

    # Never return undef because it screws up the CSV data
    return '' unless defined( $val );

    return $self->is_date_time  ? $self->datetime_value( $val )
                                : $self->escape_dateish( $val );  # HACK
}

sub is_meta      { shift()->{meta} }

sub is_date_time { shift()->{date_time} }

# Human readable format for date time columns
sub datetime_value { MT::Util::format_ts( '%Y-%m-%d %H:%M:%S', +shift ) }

# Escape non-date values that look like a date to force text and not 
# auto-convert. See:
# http://stackoverflow.com/questions/165042/stop-excel-from-automatically-converting-certain-text-values-to-dates
sub escape_dateish {
    my ( $self, $val ) = @_;

    if ($val =~ m!^(\d+[-./])?\d+[-./]\d+! ) {
        $val = q("="").$val.q(""");
    }

    return $val;
}

1;

__END__
