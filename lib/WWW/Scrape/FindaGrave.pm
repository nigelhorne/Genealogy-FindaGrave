package WWW::Scrape::FindaGrave;

use warnings;
use strict;
use WWW::Mechanize::GZip;
use LWP::UserAgent;
use HTML::SimpleLinkExtor;

=head1 NAME

WWW::Scrape::FindaGrave - Scrape the FindaGrave site

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use HTTP::Cache::Transparent;  # be nice
    use WWW::Scape::FindaGrave;

    HTTP::Cache::Transparent::init({
    	BasePath => '/var/cache/findagrave'
    });
    my $f = WWW::Scrape::FindaGrave->new({
    	firstname => 'John',
    	lastname => 'Smith',
    	country => 'England',
    	dod => 1862
    });

    while(my $url = $f->get_next_entry()) {
    	print "$url\n";
    }
}

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	return unless(defined($class));

	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	my $rc = {
		mech => $args{'mech'} || WWW::Mechanize::GZip->new(),
		dob => $args{'dob'},
		dod => $args{'dod'},
		country => $args{'country'},
		firstname => $args{'firstname'},
		middlename => $args{'middlename'},
		lastname => $args{'lastname'},
	};

	my $resp = $rc->{'mech'}->get('http://www.findagrave.com/cgi-bin/fg.cgi');
	unless($resp->is_success()) {
		die $resp->status_line;
	}

	my %fields = (
		GSfn => $rc->{'firstname'},
		GSln => $rc->{'lastname'},
		GSiman => 0,
		GSpartial => 0,
	);

	if($rc->{dod}) {
		$fields{GSdy} = $rc->{dod};
		$fields{GSdyrel} = 'in';
	} elsif($rc->{'dob'}) {
		$fields{GSby} = $rc->{dob};
		$fields{GSbyrel} = 'in';
	}

	if($rc->{'middlename'}) {
		$fields{GSmn} = $rc->{'middlename'};
	}

	# Don't enable this.  If we know the date of birth but findagrave
	# doesn't, findagrave will miss the match. Of course, the downside
	# of not doing this is that you will get false positives.  It's really
	# a problem with findagrave.
	# if($dob) {
		# $fields{GSby} = $dob;
		# $fields{GSbyrel} = 'in';
	# }

	if($rc->{'country'}) {
		if($rc->{'country'} eq 'United States') {
			$fields{GScntry} = 'The United States';
		} else {
			$fields{GScntry} = $rc->{'country'};
		}
	}

	$resp = $rc->{'mech'}->submit_form(
		form_number => 1,
		fields => \%fields,
	);
	unless($resp->is_success) {
		die $resp->status_line;
	}
	if($resp->content =~ /Sorry, there are no records in the Find A Grave database matching your query\./) {
		$rc->{'matches'} = 0;
		return bless $rc, $class;
	}
	if($resp->content =~ /<B>(\d+)<\/B>\s+total matches/mi) {
		$rc->{'matches'} = $1;
		return bless $rc, $class if($rc->{'matches'} == 0);
	}

	# Shows 40 per page
	$rc->{'base'} = $resp->base();
	$rc->{'ua'} = LWP::UserAgent->new(
			keep_alive => 1,
			agent => __PACKAGE__,
			from => 'foo@example.com',
			timeout => 10,
		);

	$rc->{'ua'}->env_proxy(1);
	$rc->{'index'} = 0;
	$rc->{'resp'} = $resp;

	return bless $rc, $class;
}

=head2 get_next_entry

=cut

sub get_next_entry
{
	my $self = shift;

	return if($self->{'matches'} == 0);

	my $rc = pop @{$self->{'results'}};
	return $rc if $rc;

	return if($self->{'index'} >= $self->{'matches'});

	my $firstname = $self->{'firstname'};
	my $lastname = $self->{'lastname'};
	my $dod = $self->{'dod'};
	my $dob = $self->{'dob'};

	my $base = $self->{'resp'}->base();
	my $e = HTML::SimpleLinkExtor->new($base);
	$e->remove_tags('img', 'script');
	$e->parse($self->{'resp'}->content);

	foreach my $link ($e->links) {
		my $match = 0;
		if($dod) {
			if($link =~ /www.findagrave.com\/cgi-bin\/fg.cgi\?.*&GSln=\Q$lastname\E.*&GSfn=\Q$firstname\E.*&GSdy=\Q$dod\E.*&GRid=\d+/i) {
				$match = 1;
			}
		} elsif(defined($dob)) {
			if($link =~ /www.findagrave.com\/cgi-bin\/fg.cgi\?.*&GSln=\Q$lastname\E.*&GSfn=\Q$firstname\E.*&GSby=\Q$dob\E.*&GRid=\d+/i) {
				$match = 1;
			}
		}
		if($match && $self->{'country'}) {
			my $country = $self->{'country'};
			if($self->{'resp'}->content !~ /\Q$country\E/i) {
				$match = 0;
			}
		}
		if($match) {
			push @{$self->{'results'}}, $link;
		}
	}
	$self->{'index'}++;
	if($self->{'index'} <= $self->{'matches'}) {
		my $index = $self->{'index'};
		$self->{'resp'} = $self->{'ua'}->get("$base&sr=$index");
	}

	return pop @{$self->{'results'}};
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-scrape-findagrave at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Scape-FindaGrave>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

L<http://https://github.com/nigelhorne/gedgrave>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Scape::FindaGrave


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Scape-FindaGrave>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Scape-FindaGrave>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Scape-FindaGrave>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Scape-FindaGrave/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Nigel Horne.

This program is released under the following licence: GPL


=cut

1; # End of WWW::Scape::FindaGrave
