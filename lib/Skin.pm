package Skin;

use strict;
use warnings;

sub new {
	my ($class, $name ) = @_;
	my $self = {
		'name' => $name,
		'attachments' => {},
	};

	return bless $self, $class;
}

sub addAttachment {
	my ($self, $slotName, $name, $attachment ) = @_;
	die "attachment cannot be null." unless defined $attachment;
	$self->{'attachments'}{$slotName}{$name} = $attachment;
}

sub getAttachment {
	my ($self, $slotName, $name ) = @_;
	return $self->{'attachments'}{$slotName}{$name};
}

sub getName { shift->{'name'};}

1;
