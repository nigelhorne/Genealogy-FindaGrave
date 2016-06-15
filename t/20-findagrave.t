use strict;
use warnings;
use Test::Most tests => 12;
use Test::NoWarnings;
use Test::URI;

BEGIN {
	use_ok('WWW::Scrape::FindaGrave');
}

FINDAGRAVE: {
	my $f = WWW::Scrape::FindaGrave->new({
		firstname => 'Daniel',
		lastname => 'Culmer',
		country => 'England',
		date_of_death => 1862
	});
	ok(defined $f);
	ok($f->isa('WWW::Scrape::FindaGrave'));

	while(my $link = $f->get_next_entry()) {
		diag($link);
		uri_host_ok($link, 'www.findagrave.com');
	}
	ok(!defined($f->get_next_entry()));

	$f = WWW::Scrape::FindaGrave->new({
		firstname => 'xyzzy',
		lastname => 'plugh',
		country => 'Canada',
		date_of_birth => 1862
	});

	ok(defined $f);
	ok($f->isa('WWW::Scrape::FindaGrave'));
	ok(!defined($f->get_next_entry()));

	$f = WWW::Scrape::FindaGrave->new({
		firstname => 'Daniel',
		middlename => 'John',
		lastname => 'Culmer',
		country => 'England',
		date_of_death => 1862
	});
	ok(defined $f);
	ok($f->isa('WWW::Scrape::FindaGrave'));
	ok(!defined($f->get_next_entry()));
}
