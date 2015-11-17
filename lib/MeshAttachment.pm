package MeshAttachment;
use base qw(Attachment);
use strict;
use warnings;

sub new {
	my $attachment = shift->SUPER::new(@_);
	$attachment->{'region'} = undef;
	$attachment->{'path'} = undef;
	$attachment->{'vertices'} = [];
	$attachment->{'regionUVs'} = [];
	$attachment->{'triangles'} = [];
	$attachment->{'worldVertices'} = [];
	$attachment->{'color'} = Color->new(1,1,1,1);
	$attachment->{'hullLength'} = undef;

	$attachment->{'edges'} = undef;
	$attachment->{'width'} = undef;
	$attachment->{'height'} = undef;

	return $attachment;
}

sub setRegion {
	my ($self, $region) = @_;
	die "region cannot be null." unless defined $region;
	$self->{'region'} = $region;
}

sub getRegion {
	my ($self) = @_;
	die "Region has not been set: " . __PACKAGE__ unless defined $self->{'region'};
	return $self->{'region'};
}

sub updateUVs {
	my ($self) = @_;

	my $verticesLength = @{$self->{'vertices'}};
	my $worldVerticesLength = $verticesLength / 2 * 5;
	my ($u, $v, $width, $height);

	my $region = $self->{'region'};

	if ( @$region == 0) {
		$u = $v = 0;
		$width = $height = 1;
	} else {
		$u = $region->getU();
		$v = $region->getV();
		$width = $region->getU2() - $u;
		$height = $region->getV2() - $v;
	}

	my $regionUVs = $self->{'regionUVs'};
	my $worldVertices = $self->{'worldVertices'};
	if ( blessed($region) eq 'AtlasRegion' && $region->{'rotate'} ) {
		for ( my ($i, $w) = (0,3); $i < $verticesLength; $i += 2, $w += 5) {
			$worldVertices->[$w] = $u + $regionUVs->[$i + 1] * $width;
			$worldVertices->[$w + 1] = $v + $height - $regionUVs->[$i] * $height;
		}
	} else {
		for (my ($i,$w) = (0,3); $i < $verticesLength; $i += 2, $w += 5) {
			$worldVertices->[$w] = $u + $regionUVs->[$i] * $width;
			$worldVertices->[$w + 1] = $v + $regionUVs->[$i + 1] * $height;
		}
	}
}

sub updateWorldVertices {
	my ( $self, $slot, $premultipliedAlpha) = @_;

	my $skeleton = $slot->getSkeleton();
	my $skeletonColor = $skeleton->getColor();
	my $slotColor = $slot->getColor();
	my $meshColor = $self->{'color'};
	my $a = $skeletonColor->{'a'} * $slotColor->{'a'} * $meshColor->{'a'} * 255;
	my $multiplier = $premultipliedAlpha ? $a : 255;
	die "NumberUtils.intToFloatColor";
	my $color;
# = NumberUtils.intToFloatColor( 
#			(int($a) << 24) 
#				| (int(skeletonColor.b * slotColor.b * meshColor.b * multiplier) << 16) 
#				| (int(skeletonColor.g * slotColor.g * meshColor.g * multiplier) << 8) 
#				| (int(skeletonColor.r * slotColor.r * meshColor.r * multiplier));

	my $worldVertices = $self->{'worldVertices'};
	my $slotVertices = $slot->getAttachmentVertices();
	my $vertices = $self->{'vertices'};
	if ( @$slotVertices == @$vertices ) {
#		$vertices = slotVertices.items;
	}

	my $bone = $slot->getBone();
	my $x = $skeleton->getX() + $bone->getWorldX();
	my $y = $skeleton->getY() + $bone->getWorldY();
	my $m00 = $bone->getM00();
	my $m01 = bone->getM01();
	my $m10 = bone->getM10();
	my $m11 = bone->getM11();
	for ( my ($v,$w,$n) = (0,0,@$worldVertices); $w < $n; $v += 2, $w += 5) {
		my $vx = $vertices->[$v];
		my $vy = $vertices->[$v + 1];
		$worldVertices->[$w] = $vx * $m00 + $vy * $m01 + $x;
		$worldVertices->[$w + 1] = $vx * $m10 + $vy * $m11 + $y;
		$worldVertices->[$w + 2] = $color;
	}
}

sub getWorldVertices { shift->{'worldVertices'};}
sub getVertices { shift->{'vertices'};}
sub setVertices { pop->{'vertices'} = pop;}
sub getTriangles { shift->{'triangles'};}
sub setTriangles { pop->{'triangles'} = pop;}
sub getRegionUVs { shift->{'regionUVs'};}
sub setRegionUVs { pop->{'regionUVs'} = pop;}
sub getEdges { shift->{'edges'};}
sub setEdges { pop->{'edges'} = pop;}
sub getOffset { shift->{'offset'};}
sub getWidth { shift->{'width'};}
sub setWidth { pop->{'width'} = pop;}
sub getHeight { shift->{'height'};}
sub setHeight { pop->{'height'} = pop;}
sub getColor { shift->{'color'};}
sub setColor { pop->{'color'} = pop;}
sub getPath { shift->{'path'};}
sub setPath { pop->{'path'} = pop;}
sub getHullLength { shift->{'hullLength'};}
sub setHullLength { pop->{'hullLength'} = pop;}

1;