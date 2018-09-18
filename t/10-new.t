#!perl -wT

use strict;

use Test::Most;
use Genealogy::FindaGrave;

NEW: {
	if(-e 't/online.enabled') {
		plan tests => 1;

		my $args = {
			'firstname' => 'john',
			'lastname' => 'smith',
			'date_of_birth' => 1912
		};

		isa_ok(Genealogy::FindaGrave->new($args), 'Genealogy::FindaGrave', 'Creating Genealogy::FindaGrave object');
	} else {
		plan skip_all => 'On-line tests disabled';
	}
}
