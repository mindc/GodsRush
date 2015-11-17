package SkeletonBinary;

use strict;
use warnings;

use lib qw(/usr/lib/matcom/tools/lib);
use Matcom qw(
    bin_pretty
);

use Data::Dumper;
use Scalar::Util qw(blessed);
use DataInput;
use AttachmentType;
use Animation;
use BoneData;
use SkeletonData;
use Skin;
use SlotData;
use EventData;
use Event;
use RegionAttachment;
use MeshAttachment;
use BoundingBoxAttachment;
use SkinnedMeshAttachment;
use Tie::IxHash;

use constant {
	DEBUG => 1,

	CURVE_LINEAR => 0,
	CURVE_STEPPED => 1,
	CURVE_BEZIER => 2
};

$Data::Dumper::Indent = 1;

sub new {
	my ($class, $attachmentLoader) = @_;
	my $self = {};
	tie %$self, 'Tie::IxHash';
	$self = {
		'attachmentLoader' => $attachmentLoader,
		'scale' => 1
	};
	return bless $self, $class;
}

sub getScale {
	my $self = shift;
	return $self->{'scale'};
}

sub setScale {
	my ($self, $float) = @_;
	$self->{'scale'} = $float;
}

sub readSkeletonData {
	my ($self, $filename) = @_;
	my $scale = $self->{'scale'};
	my $skeletonData = SkeletonData->new();

	open my $fh, "<", $filename;
	my $input = DataInput->new($fh);

	$SIG{__DIE__} = sub {
		print STDERR "__DIE__ at position " . $DataInput::pos . "\n";
		die @_;
	};

	#bones
	logger($input,"bones");
	for ( my ($i, $n) = (0, $input->readInt(1)); $i < $n; $i++ ) {
		my $boneName = $input->readString();
		
		my $parent = undef;
		my $parentName = $input->readString();
		logger($input," bone $i/$n $parentName/$boneName");

		if ( $parentName ne '' ) {
			$parent = $skeletonData->findBone($parentName);
		}

		my $boneData = BoneData->new($boneName, $parent);
		$boneData->{'length'} = $input->readFloat();
		$boneData->{'x'} = $input->readFloat();
		$boneData->{'y'} = $input->readFloat();
		$boneData->{'rotation'} = $input->readFloat();
		$boneData->{'scaleX'} = $input->readFloat();
		$boneData->{'scaleY'} = $input->readFloat();
		$boneData->{'inheritScale'} = $input->readBoolean();
		$boneData->{'inheritRotation'} = $input->readBoolean();
		$skeletonData->addBone($boneData);
	}

	#IK constraints

	#slots
	logger($input,"slots");
	for ( my($i,$n) = (0, $input->readInt(1)); $i < $n; $i++) {
		my $slotName = $input->readString();
		logger($input," slot $i/$n $slotName");
		my $boneData = $skeletonData->findBone($input->readString());
		my $slotData = SlotData->new($slotName, $boneData);
		$slotData->{'attachmentName'} = $input->readString();
		$slotData->{'color'} = Color->new($input->readFloat(),$input->readFloat(),$input->readFloat(),$input->readFloat());
		$slotData->{'blendMode'} = $input->readInt(1);
		$skeletonData->addSlot($slotData);
	} 

	#skins
	logger($input,"skins");
	for ( my ($i, $n) = (0, $input->readInt(1)); $i < $n; $i++ ) {
		$skeletonData->addSkin($self->readSkin($input, $input->readString(),$skeletonData));
	}

	#events
	logger($input,"events");
	for ( my ($i, $n) = (0, $input->readInt(1)); $i < $n; $i++ ) {
		my $eventData = EventData->new($input->readString());
		logger($input," event $i/$n ".$eventData->getName());
		$eventData->{'intValue'} = $input->readInt();
		$eventData->{'floatValue'} = $input->readFloat();
		$eventData->{'stringValue'} = $input->readString();
		$skeletonData->addEvent($eventData);
	}

	#animations
	logger($input,"animations");
	for ( my ($i, $n) = (0, $input->readInt(1)); $i < $n; $i++ ) {
		my $animationName = $input->readString();
		logger($input," animation $i/$n $animationName");
		$self->readAnimation($animationName, $input, $skeletonData);
#		die "[".$input->tell."] after first animation\n".bin_pretty($input->read(512));
	}

	return $skeletonData;
}

sub readSkin {
	my ($self, $input, $skinName, $skeletonData) = @_;
	logger($input," skin $skinName");
	my $slotCount = $input->readInt(1);
	return undef if $slotCount == 0;
	my $skin = Skin->new($skinName);
	for ( my $i = 0; $i < $slotCount; $i++ ) {
		my $slotName = $input->readString();
		logger($input,"  slot $i/$slotCount $slotName");		
		for ( my ($ii, $nn) = (0, $input->readInt(1)); $ii < $nn; $ii++ ) {
			my $attachmentName = $input->readString();
			logger($input,"    attachment $ii/$nn $attachmentName");		
			$skin->addAttachment($slotName, $attachmentName, $self->readAttachment($input, $skin, $attachmentName, $skeletonData));
		}
	}
	return $skin;	
}

sub readAttachment {
	my ($self, $input, $skin, $attachmentName, $skeletonData) = @_;
	my $scale = $self->{'scale'};
	my $name;# = $input->readString();
	$name = $attachmentName;# if $name eq '';
	my $attachmentType = $input->readInt(1);

	logger($input,"     attachmentType $attachmentType");

	for ( $attachmentType ) {
		$_ == AttachmentType::region && return do {
			logger($input,"     REGION");
            my $path = $input->readString();
            $path = $name if $path eq '';
			my $region = $self->{'attachmentLoader'}->newRegionAttachment($skin, $name, $path);
			return undef unless defined $region;

			$region->{'path'} = $path;
			$region->{'x'} = $input->readFloat() * $scale;
            $region->{'y'} = $input->readFloat() * $scale;
            $region->{'scaleX'} = $input->readFloat();
            $region->{'scaleY'} = $input->readFloat();
            $region->{'rotation'} = $input->readFloat();
            $region->{'width'} = $input->readFloat();
            $region->{'height'} = $input->readFloat();

            $region->{'r'} = $input->readInt();
            $region->{'g'} = $input->readInt();
            $region->{'b'} = $input->readInt();
            $region->{'a'} = $input->readInt();
            $region;
		};

		$_ == AttachmentType::boundingbox && return do {
			logger($input,"     BOUNDINGBOX");
            my $box = $self->{'attachmentLoader'}->newBoundingBoxAttachment($skin, $name);
			return undef unless defined $box;
			$box->setVertices($input->readFloatArray(), $scale);
			$box;
		};

		$_ == AttachmentType::mesh && return do {
			logger($input,"     MESH");

            my $path = $input->readString();

            $path = $name if $path eq '';
			my $mesh = $self->{'attachmentLoader'}->newMeshAttachment($skin, $name, $path);
			return undef unless defined $mesh;
			$mesh->setPath($path);
			$mesh->setRegionUVs($input->readFloatArray(1));
#			logger(Dumper ['uvs' , $mesh->getRegionUVs()]);
			$mesh->setHullLength($input->readInt());
			$mesh->setVertices($input->readFloatArray($self->{'scale'}));
#			logger(Dumper ['vertices' , $mesh->getVertices()]);

			$mesh->setTriangles($input->readIntArray());
#			logger(Dumper [ 'triangles',$mesh->getTriangles()]);

			
#			logger($input->tell);
			$mesh->setColor(
				Color->new(
					$input->readFloat(),
					$input->readFloat(),
					$input->readFloat(),
					$input->readFloat()
				)
			);



			$mesh->setEdges($input->readIntArray());
			logger($input->tell . Dumper[ 'edges' , $mesh->getEdges()]);

			

            $mesh->setWidth($input->readFloat() * $scale);
            $mesh->setHeight($input->readFloat() * $scale);

			logger($input->tell. Dumper [ $mesh->getWidth(), $mesh->getHeight() ]);
			#die bin_pretty($input->read(512));			
			#die Dumper $mesh;
			$mesh;
		};

		$_ == AttachmentType::skinnedmesh && return do {
			logger($input,"     SKINNEDMESH");
            my $path = $input->readString();
            $path = $name if $path eq '';
			my $mesh = $self->{'attachmentLoader'}->newSkinnedMeshAttachment($skin, $name, $path);
			return undef unless defined $mesh;

			$mesh->setPath($path);
			$mesh->setRegionUVs($input->readFloatArray(1));


			$mesh->setBones($input->readIntArray());
			$mesh->setWeights($input->readFloatArray($self->{'scale'}));
			$mesh->setTriangles($input->readIntArray());
			$mesh->computeVertices();
			$mesh->setColor(
				Color->new(
					$input->readFloat(),
					$input->readFloat(),
					$input->readFloat(),
					$input->readFloat()
				)
			);

			$mesh->setHullLength($input->readInt());
			$mesh->setEdges($input->readIntArray());

			$mesh->setWidth($input->readFloat());
			$mesh->setHeight($input->readFloat());

#			die Dumper scalar @{$mesh->{'worldVertices'}};
			$mesh;
			
		};
	}
}

sub readAnimation {
	my ($self, $name, $input, $skeletonData) = @_;

    my $timelines = [];
    my $scale = $self->{'scale'};

	logger($input," UNKNOWN INT ". $input->readInt());

	my $timelines_count = $input->readInt();
	logger($input," TIMELINES " . $timelines_count);

	#slot timelines
    for ( my ($i,$n) = (0,$input->readInt()); $i < $n; $i++ ) {
        my $slotName = $input->readString();
		logger($input,"  slot $i/$n $slotName");
		for ( my ($ii, $nn) = (0, $input->readInt()); $ii < $nn; $ii++ ) {
            my $timelineType = $input->readInt();
            my $frameCount = $input->readInt();

            for ( $timelineType ) {
				#attachment
                $_ == 0 && do {
					logger($input,"   timelineType ATTACHMENT $frameCount");
					my $timeline = AttachmentTimeline->new($frameCount);
					$timeline->{'slotName'} = $slotName;
					for ( my $frameIndex = 0; $frameIndex < $frameCount; $frameIndex++ ) {
						$timeline->setFrame($frameIndex, $input->readFloat(), $input->readString());
					}
					push @$timelines,$timeline;
                    last;
                };
				#color
                $_ == 1 && do {
					logger($input,"   timelineType COLOR $frameCount");
					my $timeline = ColorTimeline->new($frameCount);
					$timeline->{'slotName'} = $slotName;
					for ( my $frameIndex = 0; $frameIndex < $frameCount; $frameIndex++ ) {
						my $time = $input->readFloat();
						$timeline->setFrame($frameIndex, $time, $input->readFloat(), $input->readFloat(), $input->readFloat(), $input->readFloat());
						$self->readCurve($input, $frameIndex, $timeline); 
                    }
					push @$timelines,$timeline;
                    last;
                };
            }
        }
    }

	#bone timelines
	for ( my($i,$n) = (0,$input->readInt(1)); $i < $n; $i++ ) {
		my $boneName = $input->readString();
		logger($input,"  bone $i/$n `$boneName`");

		my $frameCount = $input->readInt(1);
		logger($input,"   timelineType ROTATE $frameCount");
		my $timeline = RotateTimeline->new($frameCount);
		$timeline->{'boneName'} = $boneName;
        for ( my $frameIndex = 0; $frameIndex < $frameCount; $frameIndex++) { #rotate
			$timeline->setFrame($frameIndex, $input->readFloat(), $input->readFloat());
			$self->readCurve($input, $frameIndex, $timeline); 
		} 
#		print Dumper [$name, $boneName,'rotate', $timeline->{'curve'}];
		push @$timelines, $timeline;

		$frameCount = $input->readInt(1);
		logger($input,"   timelineType TRANSLATE $frameCount");
		$timeline = TranslateTimeline->new($frameCount);
		$timeline->{'boneName'} = $boneName;
        for ( my $frameIndex = 0; $frameIndex < $frameCount; $frameIndex++) { #translate
			$timeline->setFrame($frameIndex, $input->readFloat(), $input->readFloat(), $input->readFloat());
			$self->readCurve($input, $frameIndex, $timeline); 
		} 
#		print Dumper [$name, $boneName,'translate', $timeline->{'curve'}];
		push @$timelines, $timeline;

		$frameCount = $input->readInt(1);
		logger($input,"   timelineType SCALE $frameCount");
		$timeline = ScaleTimeline->new($frameCount);
		$timeline->{'boneName'} = $boneName;
        for ( my $frameIndex = 0; $frameIndex < $frameCount; $frameIndex++) { #scale
			$timeline->setFrame($frameIndex, $input->readFloat(), $input->readFloat(), $input->readFloat());
			$self->readCurve($input, $frameIndex, $timeline); 

		} 

		push @$timelines, $timeline;

	}

	logger($input,"*timelines processes: " . scalar @$timelines);	


	#ik
#	for ( my ($i, $n) = (0,$input->readInt(1)); $i < $n; $i++ ) {
#		my $ikConstraintName = $input->readString();
#	}

	#ffd
	FFD: for ( my ($i, $n) = (0,$input->readInt(1)); $i < $n; $i++ ) {
		my $skinName = $input->readString();
		if ( $skinName eq '' ) {
			logger($input," ik");
			logger($input,"  EMPTY");
			goto FFD;
		}
		logger($input," ffd");

		my $skin = $skeletonData->findSkin($skinName);
		logger($input,"  skin $i/$n $skinName");
		for ( my($ii,$nn) = (0,$input->readInt(1)); $ii < $nn; $ii++ ) {
			my $slotName = $input->readString();
			logger($input,"   slot $ii/$nn $slotName");
#			die "[".$input->tell."]\n".bin_pretty($input->read(512));
			for ( my ($iii, $nnn) = (0, $input->readInt(1)); $iii < $nnn; $iii++ ) {
				my $attachment = $skin->getAttachment($slotName, $input->readString());
#				die "[".$input->tell."]\n".bin_pretty($input->read(512));
				logger($input,"    attachment $iii/$nnn " . $attachment->getName());
				my $frameCount = $input->readInt(1);
				my $timeline = FfdTimeline->new($frameCount);
				$timeline->{'slotName'} = $slotName;
				$timeline->{'attachment'} = $attachment;
				for ( my $frameIndex = 0; $frameIndex < $frameCount; $frameIndex++) {
					logger($input,"    frame $frameIndex/$frameCount");

					my $time = $input->readFloat();
					my $vertices = [];
					my $vertexCount;

					if ( blessed($attachment) eq 'MeshAttachment' ) {
						$vertexCount = @{$attachment->getVertices()};
					} else {
						$vertexCount = @{$attachment->getWeights()} / 3 * 2;
					}

					my $start = $input->readInt(1);
					my $start2 = $input->readInt(1);
					my $end = $input->readInt(1);

#					die Dumper [ $end, $start, $start2 ];



					if ($end == 0) {
						if ( blessed($attachment) eq 'MeshAttachment' ) {
							$vertices = $attachment->getVertices();
						} else {
							$vertices = [];
						}
					} else {



						my $vertices = [];
#						logger("start: " . $start);						

						$end += $start;
						for ( my $v = $start; $v < $end; $v++) {
							$vertices->[$v] = $input->readFloat();
						}

						if ( blessed($attachment) eq 'MeshAttachment' ) {
							my $meshVertices = $attachment->getVertices();
							for ( my ($v, $vn) = (0, scalar @$vertices); $v < $vn; $v++) {
								$vertices->[$v] += $meshVertices->[$v] || 0;
							}
						}


					}

#				die "[".$input->tell."]\n".bin_pretty($input->read(512));

					$timeline->setFrame($frameIndex, $time, $vertices);
#					$self->readCurve($input, $frameIndex, $timeline) if $frameIndex < $frameCount - 1;
				}

#				die "[".$input->tell."]\n".bin_pretty($input->read(512));
				push @$timelines, $timeline;
				

			}

#			die "[".$input->tell."]\n".bin_pretty($input->read(512));
		}

	}



	logger($input," events");

	my $eventCount = $input->readInt(1);
	if ( $eventCount > 0 ) {
	    my $timeline = EventTimeline->new($eventCount);
		for ( my $i = 0; $i < $eventCount; $i++ ) {
			my $eventName = $input->readString(); 
			logger($input,"  event $i/$eventCount $eventName");
			my $time = $input->readFloat();
			my $eventData = $skeletonData->findEvent($eventName);
			my $event = Event->new($eventData);
			$event->{'intValue'} = $eventData->getInt();
			$event->{'floatValue'} = $eventData->getFloat();
			$event->{'stringValue'} = $eventData->getString();
			$timeline->setFrame($i, $time, $event);

		}
        push @$timelines,$timeline;
    } else {
		logger($input,"  EMPTY");
	}

	logger($input,"*timelines processes: " . scalar @$timelines);	
	$skeletonData->addAnimation(Animation->new($name, $timelines));
#	die "[".$input->tell."]\n".bin_pretty($input->read(512));

}

sub readCurve {
	my ($self, $input, $frameIndex, $timeline ) = @_;
	for ( $input->readInt(1) ) {
		die "[".$input->tell."] Curve Type not defined\n" . bin_pretty($input->read(512)) unless defined($_);
		$_ == CURVE_LINEAR && do {
			$timeline->setLinear($frameIndex);
			my $t = [ $input->readFloat(), $input->readFloat(), $input->readFloat(), $input->readFloat() ];
			last;
		};
		$_ == CURVE_STEPPED && do {
			$timeline->setStepped($frameIndex);
			my $t = [ $input->readFloat(), $input->readFloat(), $input->readFloat(), $input->readFloat() ];
			last;
		};
		$_ == CURVE_BEZIER && do {
			$self->setCurve($timeline, $frameIndex, $input->readFloat(), $input->readFloat(), $input->readFloat(), $input->readFloat());
			last;
		};
	}
} 

sub setCurve {
	my ($self, $timeline, $frameIndex, $cx1, $cy1, $cx2, $cy2) = @_;
	$timeline->setCurve($frameIndex, $cx1, $cy1, $cx2, $cy2);
} 

sub max ($$) { $_[$_[0] < $_[1]] }

sub logger {
	return unless DEBUG;
    my $string = shift;
	if ( ref($string) eq 'DataInput' ) {
		my $tell = $string->tell();
		$string = shift;
		print STDERR sprintf("\e[1;31m[%6d] %s\e[m\n",$tell,$string) if DEBUG;
	} else {
		print STDERR sprintf("\e[1;31m%s\e[m\n",$string) if DEBUG;
	}
}


1;