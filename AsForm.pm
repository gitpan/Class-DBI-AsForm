package Class::DBI::AsForm;
use 5.006;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( to_cgi to_field _to_textarea _to_textfield _to_select );
our $VERSION = '1.0';
use CGI qw/:standard/;

=head1 NAME

Class::DBI::AsForm - Produce HTML form elements for database columns

=head1 SYNOPSIS

    package Music::CD;
    use Class::DBI::AsForm;
    use base 'Class::DBI';
    use CGI qw/:standard/;
    ...

    sub create_or_edit {
        my $class = shift;
        my %cgi_field = $class->to_cgi;
        return start_form,
               (map { "<b>$_</b>: ". $cgi_field{$_}." <br>" } $class->Columns),
               end_form;
    }

    # <form method="post"...>
    # Title: <input type="text" name="Title" /> <br>
    # Artist: <select name="Artist"> 
    #           <option value=1>Grateful Dead</option>
    #           ...
    #         </select>
    # ...
    # </form>

=head1 DESCRIPTION

This module helps to generate HTML forms for creating new database rows
or editing existing rows. It maps column names in a database table to
HTML form elements which fit the schema. Large text fields are turned
into textareas, and fields with a has-a relationship to other
C<Class::DBI> tables are turned into select drop-downs populated with
objects from the joined class.

=head1 METHODS

The module is a mix-in which adds two additional methods to your
C<Class::DBI>-derived class. 

=head2 to_cgi

This returns a hash mapping all the column names of the class to HTML 
snippets.

=cut

sub to_cgi {
    my $class = shift;
    map { $_ => $class->to_field($_) } $class->columns;
}

=head2 to_field($field [, $how])

This maps an individual column to a form element. The C<how> argument
can be used to force the field type into one of C<textfield>, C<textarea>
or C<select>; you can use this is you want to avoid the automatic detection
of has-a relationships.

=cut

sub to_field {
    my ($class, $field, $how) = @_;
    if ($how and $how =~ /^(text(area|field)|select)$/) {
        no strict 'refs';
        my $meth = "_to_$how";
        return $class->$meth($field);
    }
    my $hasa = $class->__hasa_rels->{$field};
    return $class->_to_select($field, $hasa->[0])
        if defined $hasa and $hasa->[0]->isa("Class::DBI");

    my $type = $class->__data_type->{$field};
    return $class->_to_textarea($field)
        if $type and $type =~ /^(TEXT|BLOB)$/i;
    return $class->_to_textfield($field);
}

sub _to_textarea {
    my ($self, $col) = @_;
    return textarea(-name => $col, -default => (ref $self && $self->$col));
}

sub _to_textfield {
    my ($self, $col) = @_;
    return textfield(-name => $col, -default => (ref $self && $self->$col));
}

sub _to_select {
    my ($self, $col, $hint) = @_;
    my $has_a_class = $hint || $self->__hasa_rels->{$col}->[0];
    my @objs = $has_a_class->retrieve_all;
    my $sel = -1;
    if (ref $self) { $sel = $self->$col()->id }
    my %labels = map { $_->id => "".$_ } @objs;
    return popup_menu( -name => $col,
                       -values => [ map {$_->id} @objs ],
                       -default => $sel,
                       -labels => \%labels );
}


# Preloaded methods go here.

1;

=head1 AUTHOR

Simon Cozens, C<simon@kasei.com>

=head1 SEE ALSO

L<Class::DBI>, L<Class::DBI::FromCGI>.

=cut
