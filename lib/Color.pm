package Color;

use strict;
use warnings;

sub new {
	my ($class, $r, $g, $b, $a) = @_;
	my $self = {};
	$self = {
		'r' => $r,
		'g' => $g,
		'b' => $b,
		'a' => $a
	};
	return bless $self, $class;
}


sub rgba8888ToColor {
	my ( $color, $value ) = @_;
	$color->{'r'} = (($value & 0xff000000) >> 24) / 255;
	$color->{'g'} = (($value & 0x00ff0000) >> 16) / 255;
	$color->{'b'} = (($value & 0x0000ff00) >> 8) / 255;
	$color->{'a'} = (($value & 0x000000ff)) / 255;
}

1;