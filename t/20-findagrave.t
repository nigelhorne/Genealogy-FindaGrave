use strict;
use warnings;
use Test::Most tests => 5;
use Test::NoWarnings;

BEGIN {
	use_ok('WWW::Scrape::FindaGrave');
}

FINDAGRAVE: {
	my $i = new_ok('WWW::Scrape::FindaGrave');
	my $f = WWW::Scrape::FindaGrave->new({
		firstname => 'Daniel',
		lastname => 'Culmer',
		country => 'England',
		dod => 1862
	});
	ok(defined $f);
	ok($f->isa('WWW::Scrape::FindaGrave'));

	while(my $link = $f->get_next_entry()) {
		diag($link);
	}
}
