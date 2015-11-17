package BoundingBoxAttachment;
use base qw(Attachment);

use strict;
use warnings;
use Data::Dumper;

sub new {
	my $attachment = shift->SUPER::new(@_);
	$attachment->{'vertices'} = [];
	return $attachment;
}

sub computeWorldVertices {
	my ($self, $bone, $worldVertices) = @_;
	my $skeleton = $bone->getSkeleton();
	my $x = $skeleton->getX() + $bone->getWorldX();
	my $y = $skeleton->getY() + $bone->getWorldY();
	my $m00 = $bone->getM00();
	my $m01 = $bone->getM01();
	my $m10 = $bone->getM10();
	my $m11 = $bone->getM11();

	my $vertices = $self->{'vertices'};
	for ( my ($i, $n) = (0, @$vertices); $i < $n; $i += 2 ) {
		my $px = $vertices->[$i];
		my $py = $vertices->[$i + 1];
		$worldVertices->[$i] = $px * $m00 + $py * $m01 + $x;
		$worldVertices->[$i + 1] = $px * $m10 + $py * $m11 + $y;
	}
}

sub getVertices { shift->{'vertices'};}
sub setVertices { 
	my ($self, $vertices) = @_;
	$self->{'vertices'} = $vertices;
}

1;