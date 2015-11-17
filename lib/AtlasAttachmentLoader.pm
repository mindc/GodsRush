package AtlasAttachmentLoader;

use strict;
use warnings;
use RegionAttachment;
use MeshAttachment;
use SkinnedMeshAttachment;
use BoundingBoxAttachment;
use Data::Dumper;
use Carp qw(confess);

sub new {
	my ($class, $atlas ) = @_;
	my $self = {};
	tie %$self, 'Tie::IxHash';
	$self = {
		'atlas' => $atlas,
	};
	return bless $self, $class;
}

sub newRegionAttachment {
	my ( $self, $skin, $name, $path) = @_;
	my $region = $self->{'atlas'}->findRegion($path);
	confess("Region not found in atlas: " . $path . " (region attachment: " . $name . ")") unless defined $region;
	my $attachment = RegionAttachment->new($name);
	$attachment->setRegion($region);
	return $attachment;
}

sub newMeshAttachment {
	my ( $self, $skin, $name, $path ) = @_;
	my $region = $self->{'atlas'}->findRegion($path);
	die "Region not found in atlas: " . $path . " (region attachment: " . $name . ")" unless defined $region;
	my $attachment = MeshAttachment->new($name);
	$attachment->setRegion($region);
	return $attachment;
}

sub newSkinnedMeshAttachment {
	my ( $self, $skin, $name, $path ) = @_;
	my $region = $self->{'atlas'}->findRegion($path);
	die "Region not found in atlas: " . $path . " (region attachment: " . $name . ")" unless defined $region;
	my $attachment = SkinnedMeshAttachment->new($name);
	$attachment->setRegion($region);
	return $attachment;
}

sub newBoundingBoxAttachment {
	my ( $self, $skin, $name ) = @_;
	return BoundingBoxAttachment->new($name);
}

1;

