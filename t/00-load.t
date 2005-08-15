#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::BoilerPlate' );
}

diag( "Testing Text::BoilerPlate $Text::BoilerPlate::VERSION, Perl $], $^X" );
