use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME	    	=> 'Class::DBI::AsForm',
    VERSION_FROM	=> 'AsForm.pm', # finds $VERSION
    PREREQ_PM		=> {Class::DBI => 0.94,
                        DBI => 1.21,
                        HTML::Element => 0,
                        }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM   => 'AsForm.pm', # retrieve abstract from module
    AUTHOR          => 'Simon Cozens <simon@kasei.com>'
);
