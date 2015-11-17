package SkinnedMeshAttachment;
use base qw(Attachment);
use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(blessed);

sub new {
	my $attachment = shift->SUPER::new(@_);
	$attachment->{'region'} = undef;
	$attachment->{'path'} = undef;
	$attachment->{'weights'} = [];
	$attachment->{'bones'} = [];
	$attachment->{'regionUVs'} = [];
	$attachment->{'triangles'} = [];
	$attachment->{'worldVertices'} = [];
	$attachment->{'color'} = Color->new(1,1,1,1);
	$attachment->{'hullLength'} = undef;
	$attachment->{'edges'} = [];
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

sub computeVertices {
	my ($self) = @_;
	my $weights = \@{ $self->{'weights'} };
	my $bones = \@{ $self->{'bones'} };
	my $vertices = $self->{'worldVertices'};

	while ( my $i = shift @$bones ) {
		push @$vertices,$i;
		for ( my ($ii, $nn) = (0, $i); $ii < $nn; $ii++ ) {
			push @$vertices,shift @$bones;
			push @$vertices,shift @$weights;
			push @$vertices,shift @$weights;
			push @$vertices,shift @$weights;
		}
	}
}

sub getWorldVertices { shift->{'worldVertices'};}
sub setWorldVertices { pop->{'worldVertices'} = pop;}

sub getWeights { shift->{'weights'};}
sub setWeights { pop->{'weights'} = pop;}

sub getBones { shift->{'bones'};}
sub setBones { pop->{'bones'} = pop;}

sub getEdges { shift->{'edges'};}
sub setEdges { pop->{'edges'} = pop;}


sub getTriangles { shift->{'triangles'};}
sub setTriangles { pop->{'triangles'} = pop;}


sub getWidth { shift->{'width'};}
sub setWidth { pop->{'width'} = pop;}

sub getRegionUVs { shift->{'regionUVs'};}
sub setRegionUVs { pop->{'regionUVs'} = pop;}


sub getHeight { shift->{'height'};}
sub setHeight { pop->{'height'} = pop;}
sub getColor { shift->{'color'};}
sub setColor { pop->{'color'} = pop;}
sub getPath { shift->{'path'};}
sub setPath { pop->{'path'} = pop;}
sub getHullLength { shift->{'hullLength'};}
sub setHullLength { pop->{'hullLength'} = pop;}

1;