package SkeletonData;

use strict;
use warnings;
use Tie::IxHash;
use Tie::IxHash::Easy;
use Scalar::Util qw(blessed);
use Data::Dumper;

sub new {
	my ( $class ) = @_;
	my $self = {};
	tie %$self, 'Tie::IxHash';

	@$self{qw(
		name
		bones
		slots
		skins
		defaultSkin
		events
		animations
		width
		height
		version
		hash
		imagesPath
	)} = (
		undef,
		[],
		[],
		[],
		undef,
		[],
		[],
		undef,
		undef,
		undef,
		undef,
		undef
	);

	return bless $self, $class;
}

sub addSlot {push @{shift->{'slots'}},shift;}
sub addBone {push @{shift->{'bones'}},shift;}
sub addSkin {push @{shift->{'skins'}},shift;}
sub addEvent {push @{shift->{'events'}},shift;}
sub addAnimation {push @{shift->{'animations'}},shift;}

sub findBone {
	my ($self, $boneName) = @_;
	foreach ( @{$self->{'bones'}} ) {
		return $_ if $_->{'name'} eq $boneName;
	}
	return undef;
}

sub findBoneIndex {
	my ($self, $boneName) = @_;
	my $i = 0;
	foreach ( @{$self->{'bones'}} ) {
		return $i if $_->{'name'} eq $boneName;
		$i++;
	}
	return -1;
}

sub getSlots { shift->{'slots'};}
sub getBones { shift->{'bones'};}

sub findSlot {
	my ( $self, $slotName ) = @_;
	foreach ( @{$self->{'slots'}} ) {
		return $_ if $_->{'name'} eq $slotName;
	}
	return undef;
}
sub findSlotIndex {
    my ($self, $slotName) = @_;
    my $i = 0;
    foreach ( @{$self->{'slots'}} ) {
        return $i if $_->{'name'} eq $slotName;
        $i++;
    }
    return -1;
}

sub getDefaultSkin { shift->{'defaultSkin'}; }
sub setDefaultSkin { pop->{'defaultSkin'} = pop; }

sub findSkin {
	my ($self, $skinName ) = @_;
	foreach ( @{$self->{'skins'}} ) {
		return $_ if $_->{'name'} eq $skinName;
	}
	return undef;
}

sub getSkins { shift->{'skins'};}

sub findEvent {
	my ($self, $eventDataName ) = @_;
	foreach ( @{$self->{'events'}} ) {
		return $_ if $_->{'name'} eq $eventDataName;
	}
	return undef;
}

sub getEvents { shift->{'events'}; }

sub findAnimation {
	my ($self, $animationName ) = @_;
	foreach ( @{$self->{'animations'}} ) {
		return $_ if $_->{'name'} eq $animationName;
	}
	return undef;
}

sub getName { shift->{'name'}; }
sub setName { pop->{'name'} = pop;}
sub getWidth { shift->{'width'};}
sub setWidth { pop->{'width'} = pop;}
sub getHeight { shift->{'height'};}
sub setHeight { pop->{'height'} = pop;}

sub getStructure {
	my ($self) = @_;
	my $o = {};
	tie %$o, 'Tie::IxHash';


	$o->{'bones'} = [];
	foreach my $bone ( @{$self->{'bones'}} ) {
		my $name = $bone->getName();
		my $parent = $bone->getParent();
		my $length = $bone->getLength();
		my $scaleX = $bone->getScaleX();
		my $scaleY = $bone->getScaleY();
		my $x = $bone->getX();
		my $y = $bone->getY();
		my $rotation = $bone->getRotation();

		my $d = {};
		tie %$d, 'Tie::IxHash';

		$d->{'name'} = $name;
		$d->{'parent'} = $parent->getName() if $parent;
		$d->{'length'} = sprintf("%.2f",$length)+0 if $length != 0;
		$d->{'x'} = sprintf("%.2f",$x)+0 if $x != 0;
		$d->{'y'} = sprintf("%.2f",$y)+0 if $y != 0;
		$d->{'scaleX'} = $scaleX+0 if $scaleX != 1;
		$d->{'scaleY'} = $scaleY+0 if $scaleY != 1;
		$d->{'rotation'} = sprintf("%.2f",$rotation)+0 if $rotation != 0;

		push @{$o->{'bones'}},$d;
	}

	$o->{'slots'} = [];
	foreach my $slot ( @{$self->{'slots'}} ) {
		my $name = $slot->getName();
		my $boneName = $slot->getBoneData()->getName();
		my $attachmentName = $slot->getAttachmentName();

		my $d = {};
		tie %$d, 'Tie::IxHash';

		$d->{'name'} = $name;
		$d->{'bone'} = $boneName;
		$d->{'attachment'} = $attachmentName if $attachmentName;

		push @{$o->{'slots'}},$d;
	}


	$o->{'skins'} = {};
	foreach my $skin ( @{$self->{'skins'}} ) {
		my $name = $skin->getName();
		my $oo = ( $o->{'skins'}{$name} = {} );
		tie %$oo, 'Tie::IxHash';

		foreach my $slotName ( sort keys %{$skin->{'attachments'}} ) {
			my $ooo = ( $o->{'skins'}{$name}{$slotName} = {} );
			tie %$ooo, 'Tie::IxHash';

			foreach my $name ( sort keys %{$skin->{'attachments'}{$slotName}} ) {
				my $attachment = $skin->{'attachments'}{$slotName}{$name};
				my $d = {};
				tie %$d, 'Tie::IxHash';

				for ( blessed($attachment) ) {
					$_ eq 'RegionAttachment' && do {
						$d->{'x'} = sprintf("%.2f",$attachment->getX())+0 if $attachment->getX() != 0;
						$d->{'y'} = sprintf("%.2f",$attachment->getY())+0 if $attachment->getY() != 0;
						$d->{'scaleX'} = sprintf("%.2f",$attachment->getScaleX())+0 if $attachment->getScaleX() != 1;
						$d->{'scaleY'} = sprintf("%.2f",$attachment->getScaleY())+0 if $attachment->getScaleY() != 1;
						$d->{'rotation'} = sprintf("%.2f",$attachment->getRotation())+0 if $attachment->getRotation() != 0;
						$d->{'width'} = sprintf("%.2f",$attachment->getWidth())+0;
						$d->{'height'} = sprintf("%.2f",$attachment->getHeight())+0;
						last;
					};

					$_ eq 'SkinnedMeshAttachment' && do {
						$d->{'type'} = 'skinnedmesh';
						$d->{'uvs'} = [ map { sprintf("%.5f",$_)+0 } @{$attachment->getRegionUVs()} ];
						$d->{'triangles'} = $attachment->getTriangles();
						$d->{'vertices'} = [ map { sprintf("%.5f",$_)+0 } @{$attachment->getWorldVertices()} ];
						$d->{'hull'} = $attachment->getHullLength();
						$d->{'edges'} = $attachment->getEdges();
						$d->{'width'} = sprintf("%.2f",$attachment->getWidth())+0;
						$d->{'height'} = sprintf("%.2f",$attachment->getHeight())+0;
						last;
					};

					$_ eq 'BoundingBoxAttachment' && do {
						$d->{'type'} = 'boundingbox';
						$d->{'vertices'} = [ map { sprintf("%.5f",$_)+0 } @{$attachment->getVertices()} ];
						last;
					};

					$_ eq 'MeshAttachment' && do {
						$d->{'type'} = 'mesh';
						$d->{'uvs'} = [ map { sprintf("%.5f",$_)+0 } @{$attachment->getRegionUVs()} ];
						$d->{'triangles'} = $attachment->getTriangles();
						$d->{'vertices'} = $attachment->getVertices();
						$d->{'hull'} = $attachment->getHullLength();
						$d->{'edges'} = $attachment->getEdges();
						$d->{'width'} = sprintf("%.2f",$attachment->getWidth())+0;
						$d->{'height'} = sprintf("%.2f",$attachment->getHeight())+0;
						last;
					};
				}
				$ooo->{$name} = $d;
			}
		}
	}

	$o->{'events'} = {};
	tie %{$o->{'events'}}, 'Tie::IxHash';
	foreach my $event ( @{$self->{'events'}} ) {
		$o->{'events'}{$event->getName()} = {};
	}	


	my $a = ( $o->{'animations'} = {} );
	tie %$a, 'Tie::IxHash';

	foreach my $anim ( @{$self->{'animations'}} ) {
		my $aa = ( $a->{$anim->getName()} = {} );
		tie %$aa, 'Tie::IxHash';
		tie %{$aa->{'slots'}}, 'Tie::IxHash';
		tie %{$aa->{'bones'}}, 'Tie::IxHash';


		foreach my $t ( @{$anim->getTimelines()} ) {
			if ( ref $t eq 'FfdTimeline' ) {
				tie %{$aa->{'ffd'}}, 'Tie::IxHash' unless exists $aa->{'ffd'};
				tie %{$aa->{'ffd'}{'default'}}, 'Tie::IxHash' unless exists $aa->{'ffd'}{'default'};
				my $drawOrder = $t->appendStruct($aa->{'ffd'}{'default'});
			} else {
				$t->appendStruct($aa);
			}
		}
	}	

	return $o;
}

1;



	


	