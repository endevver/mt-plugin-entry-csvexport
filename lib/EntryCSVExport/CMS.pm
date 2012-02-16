package EntryCSVExport::CMS;

use strict;
use warnings;

use MT::Util qw(epoch2ts format_ts);

sub entry_csv_export {
    my $app = shift;

    my @ids = $app->param('id');

    # load the entries
    # the UI prevents users who do not have edit access to the entries
    # from selecting them for an action

    # page or entry?
    my $type    = $app->param('_type');
    my $model   = $app->model($type);
    my $entries = $model->lookup_multi( \@ids );

    require Text::CSV;
    require IO::String;
    my $csv = Text::CSV->new( { binary => 1, eol => "\n" } );
    my $out = IO::String->new;

    my $cols = $model->column_names;
    my %dt_cols = map { $_ => 1 }
        @{ $model->columns_of_type( 'datetime', 'timestamp' ) };
    my @meta_cols = map { $_->{name} } MT::Meta->metadata_by_class($model);
    $csv->print( $out, [ 'Edit URL', @$cols, @meta_cols ] );

    foreach my $e ( grep {defined} @$entries ) {
        my $entry_edit_url = $app->base
            . $app->app_uri(
            mode => 'view',
            args => {
                _type   => $e->class,
                blog_id => $e->blog_id,
                id      => $e->id
            }
            );
        $csv->print(
            $out,
            [   $entry_edit_url,
                (   map {
                             !$dt_cols{$_}
                            ? $e->$_
                            : format_ts( '%Y-%m-%d %H:%M:%S', $e->$_ )
                        } @$cols
                ),
                ( map { $e->meta($_) } @meta_cols )
            ]
        );
    }

    # exporty bits
    my $filename
        = $entries->[0]->class . "-" . epoch2ts( undef, time ) . ".csv";
    $app->{no_print_body} = 1;
    $app->set_header(
        'Content-Disposition' => "attachment; filename=$filename" );
    $app->send_http_header('text/csv');
    $app->print( ${ $out->string_ref } );
}

1;