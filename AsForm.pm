package Class::DBI::AsForm;
use 5.006;
use strict;
use warnings;
our $OLD_STYLE = 0;

use HTML::Element;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( to_cgi to_field _to_textarea _to_textfield _to_select
type_of );
our $VERSION = '2.1';
my %types_cache;

=head1 NAME

Class::DBI::AsForm - Produce HTML form elements for database columns

=head1 SYNOPSIS

    package Music::CD;
    use Class::DBI::AsForm;
    use base 'Class::DBI';
    ...

    sub create_or_edit {
        my $class = shift;
        my %cgi_field = $class->to_cgi;
        return start_form,
               (map { "<b>$_</b>: ". $cgi_field{$_}->as_HTML." <br>" } $class->Columns),
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

This returns a hash mapping all the column names of the class to
HTML::Element objects representing form widgets.

=cut

sub to_cgi {
    my $class = shift;
    %types_cache = ();
    map { $_ => $class->to_field($_) } $class->columns;
}

=head2 to_field($field [, $how])

This maps an individual column to a form element. The C<how> argument
can be used to force the field type into one of C<textfield>, C<textarea>
or C<select>; you can use this is you want to avoid the automatic detection
of has-a relationships.

=cut

sub to_field {
    my ($self, $field, $how) = @_;
    my $class = ref $self || $self;
    if ($how and $how =~ /^(text(area|field)|select)$/) {
        no strict 'refs';
        my $meth = "_to_$how";
        return $class->$meth($field);
    }
    my $hasa = $class->__hasa_rels->{$field};
    return $self->_to_select($field, $hasa->[0])
        if defined $hasa and $hasa->[0]->isa("Class::DBI");

    my $type = $class->type_of($field);
    return $self->_to_textarea($field)
        if $type and $type =~ /^(TEXT|BLOB)$/i;
    return $self->_to_textfield($field);
}

sub type_of {
    my ($class, $field) = @_;
    _fill_cache($class) if !exists $types_cache{$class."/".$field};
    $types_cache{$class."/".$field}{type};
}

sub _fill_cache {
    my $class = shift;
    my $sth = $class->db_Main->column_info(undef, undef, $class->table, '%');
    while ( my $ref = $sth->fetchrow_hashref() )
        {
            $types_cache{ $class. "/". $ref->{COLUMN_NAME} }{type} = $ref->{TYPE_NAME};
            $types_cache{ $class. "/". $ref->{COLUMN_NAME} }{'values'} 
                    = [ @{$ref->{mysql_values}} ]
            if $ref->{TYPE_NAME} =~ /SET|ENUM/i;
    }
}

sub _to_textarea {
    my ($self, $col) = @_;
    my $a = HTML::Element->new("textarea", name => $col);
    if (ref $self) { $a->push_content($self->$col) }
    $OLD_STYLE && return $a->as_HTML;
    $a;
}

sub _to_textfield {
    my ($self, $col) = @_;
    my $value = ref $self && $self->$col;
    my $a = HTML::Element->new("input", type=> "text", name => $col);
    $a->attr("value" => $value) if $value;
    $OLD_STYLE && return $a->as_HTML;
    $a;
}

sub _to_select {
    my ($self, $col, $hint) = @_;
    my $has_a_class = $hint || $self->__hasa_rels->{$col}->[0];
    my @objs = $has_a_class->retrieve_all;
    my $a = HTML::Element->new("select", name => $col);
    for (@objs) { 
        my $sel = HTML::Element->new("option", value => $_->id);
        $sel->attr("selected" => "selected") if ref $self 
                                                and eval { $_->id == $self->$col->id };
        $sel->push_content($_->stringify_self);
        $a->push_content($sel);
    }
    $OLD_STYLE && return $a->as_HTML;
    $a;
}


# Preloaded methods go here.

1;

=head1 CHANGES

Version 1.x of this module returned raw HTML instead of C<HTML::Element>
objects, which made it harder to manipulate the HTML before sending it
out. If you depend on the old behaviour, set C<$Class::DBI::AsForm::OLD_STYLE>
to a true value.

=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>

=head1 SEE ALSO

L<Class::DBI>, L<Class::DBI::FromCGI>, L<HTML::Element>.

=cut
