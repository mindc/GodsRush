package BoneData;

use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(blessed);

sub new {
	my ($class, $name, $parent) = @_;
	my $self;


	if ( blessed($name) && blessed($name) eq $class ) {
		$self = {
			'parent' => $parent,
			'name' => $name->{'name'},
			'length' => $name->{'length'},
			'x' => $name->{'x'},
			'y' => $name->{'y'},
			'rotation' => $name->{'rotation'},
			'scaleX' => $name->{'scaleX'},
			'scaleY' => $name->{'scaleY'},
			'inheritScale' => 1,
			'inheritRotation' => 1
		};
	} else {
		$self = {
			'parent' => $parent,
			'name' => $name,
			'length' => undef,
			'x' => undef,
			'y' => undef,
			'rotation' => undef,
			'scaleX' => 1,
			'scaleY' => 1,
			'inheritScale' => 1,
			'inheritRotation' => 1
		};
	}
	return bless $self, $class;
}

sub getParent {	shift->{'parent'};}
sub getName { shift->{'name'};}
sub getLength { shift->{'length'};}
sub setLength { pop->{'length'} = pop;}
sub getX { shift->{'x'};}
sub setX { pop->{'x'} = pop;}
sub getY { shift->{'y'};}
sub setY { pop->{'y'} = pop;}
sub setPosition {
	my $self = shift;
	$self->{'x'} = shift;
	$self->{'y'} = shift;
}

sub getRotation { shift->{'rotation'};}
sub setRotation { pop->{'rotation'} = pop;}
sub getScaleX { shift->{'scaleX'};}
sub setScaleX { pop->{'scaleX'} = pop;}
sub getScaleY { shift->{'scaleY'};}
sub setScaleY { pop->{'scaleY'} = pop;}
sub setScale {
	my $self = shift;
	$self->{'scaleX'} = shift;
	$self->{'scaleY'} = shift;
}

1;