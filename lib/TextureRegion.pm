package TextureRegion;
use strict;
use warnings;

sub new {
	my ($class, $name) = @_;
	my $self = {
		'name' => $name,
		'x' => undef,
		'y' => undef,
		'width' => undef,
		'height' => undef,
		'index' => undef,
		'rotate' => undef,
		'originalWidth' => undef,
		'originalHeight' => undef,
		'offsetX' => undef,
		'offsetY' => undef,
		'u' => undef,
		'v' => undef,
		'u2' => undef,
		'v2' => undef
	};
	return bless $self, $class;
}

sub getName { shift->{'name'};}

sub getX { shift->{'x'};}
sub getY { shift->{'y'};}
sub getWidth { shift->{'width'};}
sub getHeight { shift->{'height'};}
sub getU { shift->{'u'};}
sub getV { shift->{'v'};}
sub getU2 { shift->{'u2'};}
sub getV2 { shift->{'v2'};}
sub getRotate { shift->{'rotate'}; }
sub getIndex { shift->{'index'}; }
sub getOrigWidth { shift->{'originalWidth'};}
sub getOrigHeight { shift->{'originalHeight'};}


sub setX { pop->{'x'} = pop;}
sub setY { pop->{'y'} = pop;}

sub setU { pop->{'u'} = pop;}
sub setV { pop->{'v'} = pop;}
sub setU2 { pop->{'u2'} = pop;}
sub setV2 { pop->{'v2'} = pop;}


sub setWidth { pop->{'width'} = pop;}
sub setHeight { pop->{'height'} = pop;}
sub setIndex { pop->{'index'} = pop;}
sub setRotate { pop->{'rotate'} = pop;}

sub setOrigWidth { pop->{'originalWidth'} = pop;}
sub setOrigHeight { pop->{'originalHeight'} = pop;}
sub setOffsetX { pop->{'offsetX'} = pop;}
sub setOffsetY { pop->{'offsetY'} = pop;}

sub getOffsetX { shift->{'offsetX'};}
sub getOffsetY { shift->{'offsetY'};}



1;