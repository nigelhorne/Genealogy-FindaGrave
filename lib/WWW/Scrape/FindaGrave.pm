package WWW::Scrape::FindaGrave;

use warnings;
use strict;
use LWP::UserAgent;
use HTML::SimpleLinkExtor;
use LWP::Protocol::https;
use Carp;

# TODO: new interface
#
# Request:
# https://www.findagrave.com/memorial/search?firstname=Edmund&middlename=Frank&lastname=Horne&birthyear=&birthyearfilter=&deathyear=&deathyearfilter=&location=&locationId=&memorialid=&datefilter=&orderby=
#
# Results
# <a class="memorial-item" href="/memorial/92467529/edmund-frank-horne" id="sr-92467529" data-scroll-offset="1">

=head1 NAME

WWW::Scrape::FindaGrave - Scrape the Find a Grave website

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    use HTTP::Cache::Transparent;  # be nice
    use WWW::Scrape::FindaGrave;

    HTTP::Cache::Transparent::init({
	BasePath => '/var/cache/findagrave'
    });
    my $f = WWW::Scrape::FindaGrave->new({
	firstname => 'John',
	lastname => 'Smith',
	country => 'England',
	date_of_death => 1862
    });

    while(my $url = $f->get_next_entry()) {
	print "$url\n";
    }
}

=head1 SUBROUTINES/METHODS

=head2 new

Creates a WWW::Scrape::FindaGrave object.

It takes two mandatory arguments firstname and lastname.

Also one of either date_of_birth and date_of_death must be given

There are three optional arguments: middlename, ua and host.

host is the domain of the site to search, the default is www.findagrave.com.

ua is a pointer to an object that understands get and env_proxy messages, such
as L<LWP::UserAgent::Throttled>.
=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	return unless(defined($class));

	my %args;
	if(ref($_[0]) eq 'HASH') {
		%args = %{$_[0]};
	} elsif(ref($_[0])) {
		Carp::croak("Usage: __PACKAGE__->new(%args)");
	} elsif(@_ % 2 == 0) {
		%args = @_;
	}


	die "First name is not optional" unless($args{'firstname'});
	die "Last name is not optional" unless($args{'lastname'});
	die "You must give one of the date of birth or death"
		unless($args{'date_of_death'} || $args{'date_of_birth'});

	my $ua = delete $args{ua} || LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
	$ua->env_proxy(1);

	# if(!defined($param{'host'})) {
		# $ua->ssl_opts(verify_hostname => 0);	# Yuck
	# }

	my $rc = {
		ua => $ua,
		date_of_birth => $args{'date_of_birth'},
		date_of_death => $args{'date_of_death'},
		country => $args{'country'},
		firstname => $args{'firstname'},
		middlename => $args{'middlename'},
		lastname => $args{'lastname'},
		matches => 0,
		index => 0,
	};
	$rc->{'host'} = $args{'host'} || 'www.findagrave.com';

	my %query_parameters;
	if($args{'firstname'}) {
		$query_parameters{'firstname'} = $args{'firstname'};
	}
	if($args{'middlename'}) {
		$query_parameters{'middlename'} = $args{'middlename'};
	}
	if($args{'lastname'}) {
		$query_parameters{'lastname'} = $args{'lastname'};
	}
	if($args{'date_of_birth'}) {
		$query_parameters{'birthyear'} = $args{'date_of_birth'};
	}
	if($args{'date_of_death'}) {
		$query_parameters{'deathyear'} = $args{'date_of_death'};
	}
	if($args{'country'}) {
		if($args{'country'} eq 'United States') {
			$query_parameters{'location'} = 'United States of America';
			$query_parameters{'locationId'} = 'country_4';
		} elsif($args{'country'} eq 'England') {
			$query_parameters{'location'} = 'England';
			$query_parameters{'locationId'} = 'country_5';
		} else {
			$query_parameters{'location'} = $args{'country'};
		}
	}
	my $uri = URI->new("https://$rc->{host}/memorial/search");
	$uri->query_form(%query_parameters);
	my $url = $uri->as_string();

	my $resp = $ua->get($url);

	if($resp->is_error()) {
		Carp::carp("API returned error: on $url ", $resp->status_line());
		return { };
	}

	unless($resp->is_success()) {
		die $resp->status_line();
	}

	$rc->{'resp'} = $resp;
	if($resp->content() =~ /\s(\d+)\smatching record found for/mi) {
		$rc->{'matches'} = $1;
		return bless $rc, $class if($rc->{'matches'} == 0);
		$rc->{'page'} = 1;
		$rc->{'query_parameters'} = \%query_parameters;
	} else {
		$rc->{'matches'} = 0;
	}
	return bless $rc, $class;
}

=head2 get_next_entry

Returns the next match as a URL to the Find-A-Grave page.

=cut

sub get_next_entry
{
	my $self = shift;

	return if(!defined($self->{'matches'}));
	return if($self->{'matches'} == 0);

	my $rc = pop @{$self->{'results'}};
	return $rc if $rc;

	return if($self->{'index'} >= $self->{'matches'});

	my $firstname = $self->{'firstname'};
	my $lastname = $self->{'lastname'};
	# my $date_of_death = $self->{'date_of_death'};	# FIXME: check results against this
	# my $date_of_birth = $self->{'date_of_birth'};	# FIXME: check results against this

	my $base = $self->{'resp'}->base();
	my $e = HTML::SimpleLinkExtor->new($base);

	$e->remove_tags('img', 'script');
	$e->parse($self->{'resp'}->content());	# FIXME: having to parse every time

	foreach my $link ($e->links()) {
		my $match = 0;
		if($link =~ /\/memorial\/\d+\/\Q$firstname\E.+\Q$lastname\E/i) {
			$match = 1;
		}
		if($match) {
			push @{$self->{'results'}}, $link;
		}
	}
	$self->{'index'}++;
	if($self->{'index'} <= $self->{'matches'}) {
		$self->{'page'}++;
		$self->{'query_parameters'}->{'page'} = $self->{'page'};

		my $uri = URI->new("https://$self->{host}/memorial/search");
		$uri->query_form(%{$self->{'query_parameters'}});
		my $url = $uri->as_string();

		my $resp = $self->{'ua'}->get($url);
		$self->{'resp'} = $resp;

		if($resp->is_error()) {
			Carp::carp("API returned error: on $url ", $resp->status_line());
			return { };
		}

		unless($resp->is_success()) {
			die $resp->status_line();
		}
	}

	return pop @{$self->{'results'}};
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-scrape-findagrave at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Scrape-FindaGrave>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

L<https://github.com/nigelhorne/gedcom>
L<https://www.findagrave.com>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Scrape::FindaGrave

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Scrape-FindaGrave>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Scrape-FindaGrave>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Scrape-FindaGrave>

=item * Search CPAN

L<https://metacpan.org/release/WWW-Scrape-FindaGrave>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2016-2018 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1; # End of WWW::Scrape::FindaGrave
