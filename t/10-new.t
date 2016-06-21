#!perl -wT

use strict;

use Test::Most tests => 2;
use Test::NoWarnings;

use WWW::Scrape::FindaGrave;

my $args = {
	'firstname' => 'john',
	'lastname' => 'smith',
	'date_of_birth' => 1912
};

isa_ok(WWW::Scrape::FindaGrave->new($args), 'WWW::Scrape::FindaGrave', 'Creating WWW::Scrape::FindaGrave object');
