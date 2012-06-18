package EntryCSVExport::CMS;

use strict;
use warnings;
use MT::Entry;
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

    my $cols = [
        ( grep { ! m/^(category_id|created_by|modified_by|status|tangent_cache|template_id|to_ping_urls|week_number)$/ }
            @{ $model->column_names } ),
        qw( blog_name permalink status_text author_name primary_category
            secondary_categories tag_names creator last_editor )
    ];
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

package MT::Entry;

sub blog_name   { shift()->blog->name   }
sub author_name { shift()->author->name }

sub creator {
    my $e      = shift;
    my $id     = $e->created_by or return;
    my $author = MT->model('author')->lookup( $id );
    return $author->name if $author && $author->name;
}
sub last_editor {
    my $e      = shift;
    my $id     = $e->modified_by or return;
    my $author = MT->model('author')->lookup( $id );
    return $author->name if $author && $author->name;
}

sub primary_category {
    my $e = shift;
    require MT::Placement;
    my ($map) = MT::Placement->search({ entry_id => $e->id, is_primary => 1 })
        or return;

    require MT::Category;
    my ($cat) = MT::Category->lookup( $map->category_id );
    return $cat ? $cat->label : undef;
}

sub secondary_categories {
    my $e = shift;
    require MT::Placement;
    my @maps = MT::Placement->load({ entry_id => $e->id, is_primary => 0 })
        or return;

    my @cats;
    require MT::Category;
    foreach my $map ( @maps ) {
        my $cat = MT::Category->load([ $map->category_id ]) or next;
        push( @cats, $cat->label );
    }
    return join( ', ', @cats );
}

sub tag_names {
    my $e    = shift;
    my @tags = map { $_->name } $e->tags or return;
    MT::Tag->join(', ', @tags );
}


1;
