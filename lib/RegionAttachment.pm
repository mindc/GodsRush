package RegionAttachment;
use base qw(Attachment);

use strict;
use warnings;
use Scalar::Util qw(blessed);
use Data::Dumper;

use constant {
	BLX => 0,
	BLY => 1,
	ULX => 2,
	ULY => 3,
	URX => 4,
	URY => 5,
	BRX => 6,
	BRY => 7,

	X1 => 0,
	Y1 => 1,
	C1 => 2,
	U1 => 3,
	V1 => 4,
	X2 => 5,
	Y2 => 6,
	C2 => 7,
	U2 => 8,
	V2 => 9,
	X3 => 10,
	Y3 => 11,
	C3 => 12,
	U3 => 13,
	V3 => 14,
	X4 => 15,
	Y4 => 16,
	C4 => 17,
	U4 => 18,
	V4 => 19,

};

sub new {
	my $attachment = shift->SUPER::new(@_);
	$attachment->{'region'} = undef;
	$attachment->{'path'} = undef;
	$attachment->{'x'} = undef;
	$attachment->{'y'} = undef;
	$attachment->{'scaleX'} = 1;
	$attachment->{'scaleY'} = 1;
	$attachment->{'rotation'} = undef;
	$attachment->{'width'} = undef;
	$attachment->{'height'} = undef;
	$attachment->{'vertices'} = [];
	$attachment->{'offset'} = [];
	$attachment->{'color'} = Color->new(1,1,1,1);
	return $attachment;
}

sub updateOffset {
	my ($self) = @_;

	my $width = $self->getWidth();
	my $height = $self->getHeight();
	my $localX2 = $width / 2;
	my $localY2 = $height / 2;
	my $localX = - $localX2;
	my $localY = - $localY2;

		if ( blessed($self->{'region'}) eq 'AtlasRegion') {
			my $region = $self->{'region'};
			if ( $region->{'rotate'} ) {
				$localX += $region->{'offsetX'} / $region->{'originalWidth'} * $width;
				$localY += $region->{'offsetY'} / $region->{'originalHeight'} * $height;
				$localX2 -= ($region->{'originalWidth'} - $region->{'offsetX'} - $region->{'packedHeight'}) / $region->{'originalWidth'} * $width;
				$localY2 -= ($region->{'originalHeight'} - $region->{'offsetY'} - $region->{'packedWidth'}) / $region->{'originalHeight'} * $height;
			} else {
				$localX += $region->{'offsetX'} / $region->{'originalWidth'} * $width;
				$localY += $region->{'offsetY'} / $region->{'originalHeight'} * $height;
				$localX2 -= ($region->{'originalWidth'} - $region->{'offsetX'} - $region->{'packedWidth'}) / $region->{'originalWidth'} * $width;
				$localY2 -= ($region->{'originalHeight'} - $region->{'offsetY'} - $region->{'packedHeight'}) / $region->{'originalHeight'} * $height;
			}
		}
		
		my $scaleX = $self->getScaleX();
		my $scaleY = $self->getScaleY();
		$localX *= $scaleX;
		$localY *= $scaleY;
		$localX2 *= $scaleX;
		$localY2 *= $scaleY;
		my $rotation = $self->getRotation();
		my $cos = cos($rotation/180*3.14159265358979);
		my $sin = sin($rotation/180*3.14159265358979);
		my $x = $self->getX();
		my $y = $self->getY();
		my $localXCos = $localX * $cos + $x;
		my $localXSin = $localX * $sin;
		my $localYCos = $localY * $cos + $y;
		my $localYSin = $localY * $sin;
		my $localX2Cos = $localX2 * $cos + $x;
		my $localX2Sin = $localX2 * $sin;
		my $localY2Cos = $localY2 * $cos + $y;
		my $localY2Sin = $localY2 * $sin;
		my $offset = $self->{'offset'};

		$offset->[BLX] = $localXCos - $localYSin;
		$offset->[BLY] = $localYCos + $localXSin;
		$offset->[ULX] = $localXCos - $localY2Sin;
		$offset->[ULY] = $localY2Cos + $localXSin;
		$offset->[URX] = $localX2Cos - $localY2Sin;
		$offset->[URY] = $localY2Cos + $localX2Sin;
		$offset->[BRX] = $localX2Cos - $localYSin;
		$offset->[BRY] = $localYCos + $localX2Sin;
	
}

sub setRegion {
	my ($self, $region) = @_;
	die "region cannot be null." unless defined $region;

	$self->{'region'} = $region;
	my $vertices = $self->{'vertices'};

=cut
	if ( blessed($region) eq 'AtlasRegion' && $region->{'rotate'} ) {
		$vertices->[U3] = $region->getU();
		$vertices->[V3] = $region->getV2();
		$vertices->[U4] = $region->getU();
		$vertices->[V4] = $region->getV();
		$vertices->[U1] = $region->getU2();
		$vertices->[V1] = $region->getV();
		$vertices->[U2] = $region->getU2();
		$vertices->[V2] = $region->getV2();
	} else {
		$vertices->[U2] = $region->getU();
		$vertices->[V2] = $region->getV2();
		$vertices->[U3] = $region->getU();
		$vertices->[V3] = $region->getV();
		$vertices->[U4] = $region->getU2();
		$vertices->[V4] = $region->getV();
		$vertices->[U1] = $region->getU2();
		$vertices->[V1] = $region->getV2();
	}
=cut
}

sub getRegion {
	my ($self) = @_;
	die "Region has not been set: " . __PACKAGE__ unless defined $self->{'region'};
	return $self->{'region'};
}

sub updateWorldVertices {
	my ( $self, $slot, $premultipliedAlpha) = @_;

	my $skeleton = $slot->getSkeleton();
	my $skeletonColor = $skeleton->getColor();
	my $slotColor = $slot->getColor();

	my $regionColor = $self->{'color'};
		my $a = $skeletonColor->{'a'} * $slotColor->{'a'} * $regionColor->{'a'} * 255;
		my $multiplier = $premultipliedAlpha ? $a : 255;
		die "NumberUtils.intToFloatColor";
		my $color;
# = NumberUtils.intToFloatColor( 
#			(int($a) << 24) 
#				| (int($skeletonColor->{'b'} * $slotColor->{'b'} * $regionColor->{'b'} * $multiplier) << 16)
#				| (int($skeletonColor->{'g'} * $slotColor->{'g'} * $regionColor->{'g'} * $multiplier) << 8) 
#				| int($skeletonColor->{'r'} * $slotColor->{'r'} * $regionColor->{'r'} * $multiplier));

		my $vertices = $self->{'vertices'};
		my $offset = $self->{'offset'};
		my $bone = $slot->getBone();
		my $x = $skeleton->getX() + $bone->getWorldX();
		my $y = $skeleton->getY() + $bone->getWorldY();
		my $m00 = $bone->getM00();
		my $m01 = $bone->getM01();
		my $m10 = $bone->getM10();
		my $m11 = $bone->getM11();
		my ( $offsetX, $offsetY);

		$offsetX = $offset->[BRX];
		$offsetY = $offset->[BRY];
		$vertices->[X1] = $offsetX * $m00 + $offsetY * $m01 + $x; # br
		$vertices->[Y1] = $offsetX * $m10 + $offsetY * $m11 + $y;
		$vertices->[C1] = $color;

		$offsetX = $offset->[BLX];
		$offsetY = $offset->[BLY];
		$vertices->[X2] = $offsetX * $m00 + $offsetY * $m01 + $x; # bl
		$vertices->[Y2] = $offsetX * $m10 + $offsetY * $m11 + $y;
		$vertices->[C2] = $color;

		$offsetX = $offset->[ULX];
		$offsetY = $offset->[ULY];
		$vertices->[X3] = $offsetX * $m00 + $offsetY * $m01 + $x; # ul
		$vertices->[Y3] = $offsetX * $m10 + $offsetY * $m11 + $y;
		$vertices->[C3] = $color;

		$offsetX = $offset->[URX];
		$offsetY = $offset->[URY];
		$vertices->[X4] = $offsetX * $m00 + $offsetY * $m01 + $x; # ur
		$vertices->[Y4] = $offsetX * $m10 + $offsetY * $m11 + $y;
		$vertices->[C4] = $color;
	}


sub getWorldVertices { shift->{'vertices'};}
sub getOffset { shift->{'offset'};}
sub getX { shift->{'x'};}
sub setX { pop->{'x'} = pop;}
sub getY { shift->{'y'};}
sub setY { pop->{'y'} = pop;}
sub getScaleX { shift->{'scaleX'};}
sub setScaleX { pop->{'scaleX'} = pop;}
sub getScaleY { shift->{'scaleY'};}
sub setScaleY { pop->{'scaleY'} = pop;}
sub getRotation { shift->{'rotation'};}
sub setRotation { pop->{'rotation'} = pop;}
sub getWidth { shift->{'width'};}
sub setWidth { pop->{'width'} = pop;}
sub getHeight { shift->{'height'};}
sub setHeight { pop->{'height'} = pop;}
sub getColor { shift->{'path'};}
sub getPath { shift->{'path'};}
sub setPath { pop->{'path'} = pop;}

1;