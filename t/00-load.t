#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
    use_ok('WWW::Scraper::FindaGrave') || print 'Bail out!';
}

require_ok('WWW::Scraper::FindaGrave') || print 'Bail out!';

diag( "Testing WWW::Scraper::FindaGrave $WWW::Scraper::FindaGrave::VERSION, Perl $], $^X" );
