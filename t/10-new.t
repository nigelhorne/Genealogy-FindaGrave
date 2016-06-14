#!perl -wT

use strict;

use Test::Most tests => 2;

use WWW::Scraper::FindaGrave;

isa_ok(WWW::Scraper::FindaGrave->new(), 'WWW::Scraper::FindaGrave', 'Creating WWW::Scraper::FindaGrave object');
ok(!defined(WWW::Scraper::FindaGrave::new()));
