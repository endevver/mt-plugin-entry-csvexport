package EntryCSVExport::CMS;

use strict;
use warnings;
use EntryCSVExport;

sub entry_csv_export {
    my $app = shift;
    my $blog_id = $app->param('blog_id');
    my @ids   = $app->param('id');
    my $type  = $app->param('_type');         # page or entry?
    $type     =~ s{^list_}{};
    my $model = $app->model($type);

    my $exporter = EntryCSVExport->new({
        object_type => $type,
        model       => $model,
    });

    my $terms         = { class => $type };
    $terms->{id}      = \@ids    if @ids;
    $terms->{blog_id} = $blog_id if $blog_id;

    $exporter->iterator( $model->load_iter($terms) );

    defined( my $out_ref = $exporter->generate() )
        or die "EntryCSVExport generator returned no output";


    ### Derive filename for Export file ###
    my @filename = ( $model->class_label_plural,
                     MT::Util::epoch2ts( undef, time ) );

    if ( $blog_id ) {
        my $blog = $app->model('blog')->load( $blog_id );
        my $name = defined $blog->name ? $blog->name : 'blog-'.$blog->id;
        unshift( @filename, $name );
    }

    require MT::Util;
    my $filename = MT::Util::dirify( join('-', @filename ) ) . '.csv';

    $app->{no_print_body} = 1;
    $app->set_header(
        'Content-Disposition' => "attachment; filename=$filename" );
    $app->send_http_header('text/csv');

    $app->print( $$out_ref );
}


1;