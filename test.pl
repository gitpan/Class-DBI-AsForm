package Bar;
use base 'Class::DBI';
Bar->columns(All => qw/id test/);
Bar->columns(Stringify => qw/test/);
sub retrieve_all {
    bless { test => "Hi", id => 1}, shift;
}

package Foo;
use Test::More tests => 4;
use base 'Class::DBI';
use_ok("Class::DBI::AsForm");

Foo->columns(All => qw/id bar baz/);
like(Foo->to_field("baz"), qr/<input type="text" name="baz"/,
    "Ordinary text field OK");

Foo->has_a(bar => Bar);
is(Foo->to_field("bar"), '<select name="bar">
<option value="1">Hi</option>
</select>',
    "Select OK");

my $x = bless({id => 1, bar => Bar->retrieve_all(), baz => "Hello there"}), "Foo";
my %cgi = ( id => '<input type="text" name="id" value="1" />',
    bar => '<select name="bar">
<option selected="selected" value="1">Hi</option>
</select>',
            baz => '<input type="text" name="baz" value="Hello there" />'
          );
is_deeply({$x->to_cgi}, \%cgi, "All correct as an object method");
