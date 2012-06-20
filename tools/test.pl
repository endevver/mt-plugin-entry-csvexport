#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$ENV{MT_HOME}/lib", "$ENV{MT_HOME}/extlib", "$Bin/../lib";
use MT;

my ( $type, $blog_id ) = ( 'entry', 6 );


my $mt    = MT->new( Config => 'mt-config.cgi') or die MT->errstr;
my $model = $mt->model($type);

use EntryCSVExport;
my $exporter = EntryCSVExport->new({
    object_type => $type,
    model       => $model,
});

my $terms         = { class => $type };
$terms->{blog_id} = $blog_id if $blog_id;

$exporter->iterator( $model->load_iter($terms) );

defined( my $out_ref = $exporter->generate() )
    or die "EntryCSVExport generator returned no output";

print "$$out_ref\n";


__END__
