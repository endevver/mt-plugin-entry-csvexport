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
    return '' if ! defined( $val );

    # Human readable format for date time columns
    $val = format_ts( '%Y-%m-%d %H:%M:%S', $val )
        if $self->is_date_time;

    return $val;
}

sub is_meta      { shift()->{meta}      }

sub is_date_time { shift()->{date_time} }

1;


__END__
