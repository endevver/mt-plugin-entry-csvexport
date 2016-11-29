package EntryCSVExport::Data;

use strict;
use warnings;

use base qw(  Class::Accessor::Fast  Class::Data::Inheritable  );

__PACKAGE__->mk_accessors(qw(
    object_type
    model
    columns_cache
    dt_column_cache
    meta_cols_cache
));

__PACKAGE__->mk_classdata(
    Excluded => [qw/
        category_id
        tangent_cache
        template_id
        ping_count
        comment_count
        to_ping_urls
        pinged_urls
    /]
);


__PACKAGE__->mk_classdata(
    Properties => [qw/
        edit_url
        blog_name
        permalink
        status_as_text
        created_by_author
        modified_by_author
        category_label
        categories_secondary
        tags_list
    /]
);

sub validate_parameters {
    # my $self    = shift;
    # my $model   = $self->model;
    # my %dt_cols = map { $_ => 1 }
    #      @{ $model->columns_of_type( 'datetime', 'timestamp' ) };
}

sub date_time_columns {
    my $self  = shift;
    my $model = $self->model;
    unless ( $self->dt_column_cache ) {
        $self->dt_column_cache({
            map { $_ => 1 }
                @{ $model->columns_of_type( 'datetime', 'timestamp' ) }
        });
    }
    $self->dt_column_cache;
}

sub columns {
    my $self = shift;
    my $cols;
    unless ( $cols = $self->columns_cache ) {

        $self->validate_parameters();

        # The columns in the CSV export are made up of 3 different types of
        # values:
        #   - Standard columns (e.g. entry_title)
        #   - Meta columns (e.g. entry_meta_type + its value)
        #   - Shortcut properties (e.g. permalink, blog_name)
        my @cols = (
            @{( $self->standard_cols )},
            @{( $self->meta_cols     )},
            @{ $self->Properties    },
        );

        # Apply Excluded list, removing matching column
        @cols = $self->filter_columns( @cols );

        # Convert column name strings to hashrefs, if they aren't already
        # Meta columns are already in this format (see meta_cols())
        @cols = map { $self->column_hashref($_) } @cols;

        # Convert column hashrefs to full fledged objects and sort them by
        # their label property.  See EntryCSVExport::Data::Column for more
        require EntryCSVExport::Data::Column;
        @cols = sort { $a->label cmp $b->label }
                map { EntryCSVExport::Data::Column->new($_) } @cols;

        my @starters = qw(
            id
            blog_name
            basename
            status_as_text
            edit_url
            title
        );

        require Regexp::List;
        my $l  = Regexp::List->new;
        my $starters_pat = $l->list2re( @starters );

        my (%starters, @sorted);
        foreach my $c ( @cols ) {
            if ( $c->key =~ m/^$starters_pat$/ ) {
                $starters{$c->key} = $c;
            }
            else {
                push( @sorted, $c );
            }
        }
        @sorted = (@starters{@starters}, @sorted);

        $cols = \@sorted;
        $self->columns_cache($cols);
    }

    return wantarray ? @$cols : $cols;
}



sub filter_columns {
    my $self = shift;
    my @cols = @_;
    my @excluded = @{ $self->Excluded } or return;

    require Regexp::List;
    my $l  = Regexp::List->new;
    my $exclude_pat = $l->list2re( @excluded );
    grep { ! m/^$exclude_pat$/ } @cols;
}

sub column_hashref {
    my $self           = shift;
    my ( $val, $data ) = @_;

    # Convert to hash if needed
    my $colinfo = ref($val) ? $val : { key => $val };

    # Overlay values from $data hashref if present
    if ( $data ) {
        $colinfo->{$_} = $data->{$_} foreach keys %$data;
    }

    my $dt_columns = $self->date_time_columns;
    $colinfo->{date_time} = 1 if $dt_columns->{$val};

    return $colinfo;
}

sub standard_cols {
    my $cols = shift()->model->column_names;
    return wantarray ? @$cols : $cols;
}

sub meta_cols {
    my $self = shift;
    my $cols;
    unless ( $cols = $self->meta_cols_cache ) {

        my @cols = map {
            $self->column_hashref( $_->{name}, { meta => 1 } )
          } MT::Meta->metadata_by_class($self->model);
        $cols = \@cols;
        $self->meta_cols_cache($cols);
    }
    return wantarray ? @$cols : $cols;
}

sub column_headers {
    return [ map { $_->label } shift()->columns ];
}


sub row_values {
    my $self    = shift;
    my $e       = shift;
    [ map { $_->value($e) } $self->columns ];
}





##############################################
package MT::Entry;

sub blog_name   { shift()->blog->name }

sub created_by_author {
    my $e      = shift;
    my $id     = $e->created_by or return;
    my $author = MT->model('author')->lookup( $id );
    return $author->name if $author && $author->name;
}

sub modified_by_author {
    my $e      = shift;
    my $id     = $e->modified_by or return;
    my $author = MT->model('author')->lookup( $id );
    return $author->name if $author && $author->name;
}

sub category_label {
    my $cat = shift()->category or return;
    return defined $cat->label ? $cat->label : '';
}

sub categories_secondary {
    my $e          = shift;
    my $category   = $e->category;
    my $primary_id = $category ? $category->id : -1 ;
    my @cats       = @{ $e->categories };

    return join( ', ',
        map  { $_->label }
        grep { $_->id != $primary_id } @cats
    );
}

sub tags_list {
    my $e    = shift;
    my @tags = $e->tags or return;
    MT::Tag->join(', ', @tags );
}

sub edit_url {
    my $e   = shift;
    my $app = MT->instance;

    my $base;
    if ( $app->can('base') ) {
        $base = $app->base;
    }
    else {
        my $cfg  = $app->config;
        my $path = ( $cfg->AdminCGIPath || $cfg->CGIPath );
        if ( $path =~ m!^(https?://[^/]+)!i ) {
            ( my $host = $1 ) =~ s!/$!!;
            $base = $app->{__host} = $host;
        }
        else { return '' };
    }

    return $base
         . $app->app_uri(
             mode => 'view',
             args => {
                 _type   => $e->class,
                 blog_id => $e->blog_id,
                 id      => $e->id
             }
          );
}

sub status_as_text {
    my $e = shift;
    return MT::Entry::status_text( $e->status );
}


1;