package Attachment;
use strict;
use warnings;

sub new {
	my ( $class, $name) = @_;
	my $self = {
		'name' => $name
	};
	return bless $self, $class;
}

sub getName { shift->{'name'};}

1;
