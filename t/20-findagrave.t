use strict;
use warnings;
use Test::Most tests => 5;
use Test::NoWarnings;

BEGIN {
	use_ok('WWW::Scraper::FindaGrave');
}

FINDAGRAVE: {
	my $i = new_ok('WWW::Scraper::FindaGrave');
	my $f = WWW::Scraper::FindaGrave->new({
		firstname => 'Daniel',
		lastname => 'Culmer',
		country => 'England',
		dod => 1862
	});
	ok(defined $f);
	ok($f->isa('WWW::Scraper::FindaGrave'));

	while(my $link = $f->get_next_entry()) {
		diag($link);
	}
}
