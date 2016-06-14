#!perl -wT

use strict;

use Test::Most tests => 2;

use WWW::Scrape::FindaGrave;

isa_ok(WWW::Scrape::FindaGrave->new(), 'WWW::Scrape::FindaGrave', 'Creating WWW::Scrape::FindaGrave object');
ok(!defined(WWW::Scrape::FindaGrave::new()));
