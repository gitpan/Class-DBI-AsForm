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
$Class::DBI::AsForm::OLD_STYLE=1;
*type_of = sub { "varchar" };

Foo->columns(All => qw/id bar baz/);
like(Foo->to_field("baz"), qr/<input .*name="baz"/,
    "Ordinary text field OK");

Foo->has_a(bar => Bar);
is(Foo->to_field("bar"), "<select name=\"bar\"><option value=1>Hi</option></select>\n",
    "Select OK");

my $x = bless({id => 1, bar => Bar->retrieve_all(), baz => "Hello there"}, "Foo");
my %cgi = ( id => '<input name="id" type="text" value=1>
',
    bar => '<select name="bar"><option selected value=1>Hi</option></select>
',
            baz => '<input name="baz" type="text" value="Hello there">
'
          );
is_deeply({$x->to_cgi}, \%cgi, "All correct as an object method");
