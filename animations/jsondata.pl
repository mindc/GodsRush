#!/usr/bin/perl

use strict;
use warnings;
use Tie::IxHash;
use Data::Dumper;
use IO::File;
use JSON::XS;
use lib qw(../lib);

use constant {
	region => 0,
	boundingbox => 1,
	mesh => 2,
	skinnedmesh => 3,

	TIMELINE_SCALE => 0,
	TIMELINE_ROTATE => 6, #ok
	TIMELINE_TRANSLATE => 2,
	TIMELINE_ATTACHMENT => 3,
	TIMELINE_COLOR => 2, #ok
	TIMELINE_FLIPX => 5,
	TIMELINE_FLIPY => 6,

	CURVE_LINEAR => 0,
	CURVE_STEPPED => 1,
	CURVE_BEZIER => 2,

	DEBUG => 1
 
};

$Data::Dumper::Indent = 1;

my $fh = IO::File->new();

my $seek = 0;
open $fh, "<", $ARGV[0];

my $skel = {};
my $sk = $skel;
tie %$skel, 'Tie::IxHash';

get_bones($skel);
get_slots($skel);
get_skins($skel);
get_events($skel);
get_animations($skel);

print encode_json($skel);

exit;

sub exitHandler {
	die Dumper($skel);
}

sub get_events {
	my $skel = shift;
	my $s = ( $skel->{'events'} = {} );
	tie %$s, 'Tie::IxHash';

	for ( my ($i,$n) = (0,readInt()); $i < $n; $i++ ) {
		my $event = {};
		tie %$event, 'Tie::IxHash';
		$event->{'name'} = readString();
		$event->{'intValue'} = readInt();
		$event->{'floatValue'} = readFloat();
		$event->{'stringValue'} = readString();
		$s->{$event->{'name'}} = {};
	}
}

sub get_animations {
	my $skel = shift;
	my $s = ( $skel->{'animations'} = {} );
	for ( my ($i, $n ) = (0, readInt() ); $i < $n; $i++ ) {
		my $name = readString();
		logger("animations $i/$n");
		readAnimation($s,$name);
	}
}

sub readAnimation {
	my $skel = shift;
	my $animationName = shift;

	my $s = ( $skel->{$animationName} = {} );
	tie %$s, 'Tie::IxHash';


	my $timelines = [];
	my $scale = 1;
	my $duration = 0;

	logger(Dumper([readInt(),readInt()]));
	logger("animationName: $animationName");

	#slots
	my $ss;

	$ss = ( $s->{'slots'} = {} );
	tie %$ss, 'Tie::IxHash';

	for ( my ($i,$n) = (0,readInt()); $i < $n; $i++ ) {
		my $slotIndex = readString();
		logger("slots $i/$n, slotIndex: $slotIndex\e[m");
		my $sss = ( $s->{$slotIndex} = {} );

		alarm 1;
		for ( my ($ii, $nn) = (0, readInt()); $ii < $nn; $ii++ ) {
			logger("slot $ii/$nn");
			
			my $timelineType = readInt();
			my $frameCount = readInt();

#			logger("timelineType: $timelineType, frameCount: $frameCount");

			for ( $timelineType ) {
				$_ == 0 && do {
					for ( my $frameIndex = 0; $frameIndex < $frameCount; $frameIndex++ ) {
						my $attachment = {};
						tie %$attachment, 'Tie::IxHash';
						@$attachment{qw(time name)} = ( readFloat(), readString() );
						push @{$sss->{'attachment'}},$attachment;
					}
					last;
				};
				$_ == 1 && do {
					for ( my $frameIndex = 0; $frameIndex < $frameCount; $frameIndex++ ) {
						my $color = {};
						tie %$color, 'Tie::IxHash';
						@$color{qw(time r g b a u1 u2 u3 u4 u5)} = (readFloat(),readFloat(),readFloat(),readFloat(),readFloat(),readInt(),readInt(),readInt(),readInt(),readInt());
						push @{$sss->{'color'}},$color;
					}
					last;
				};
			}
		}
		alarm 0;
	}

	$ss = ( $s->{'bones'} = {} );
	tie %$ss, 'Tie::IxHash';

	for ( my($i,$n) = (0,readInt()); $i < $n; $i++ ) {
		my $boneIndex = readString();
		logger("bones $i/$n, boneIndex: $boneIndex");
		my $sss = ( $ss->{$boneIndex} = {} );
		tie %$sss, 'Tie::IxHash';	

		for ( my ($ii,$nn) = (0,readInt()); $ii < $nn; $ii++) { #rotate
			my $rotate = {};
			tie %$rotate, 'Tie::IxHash';
			@$rotate{qw(time angle curve)} = (readFloat(),readFloat(),parseCurve(readInt()));
			readInt();readInt();readInt();readInt();
			delete $rotate->{'curve'} if $rotate->{'curve'} eq 'linear';
			push @{$sss->{'rotate'}},$rotate;
		}

		for ( my ($ii,$nn) = (0,readInt()); $ii < $nn; $ii++) { #rotate
			my $translate = {};
			tie %$translate, 'Tie::IxHash';
			@$translate{qw(time x y u3 u4 u5 u6 u7)} = (readFloat(),readFloat(),readFloat(),readFloat(),readFloat(),readFloat(),readFloat(),readFloat());
			push @{$sss->{'translate'}},$translate;
		}

		for ( my ($ii,$nn) = (0,readInt()); $ii < $nn; $ii++) { #rotate
			my $scale = {};
			tie %$scale, 'Tie::IxHash';
			@$scale{qw(time x y u3 u4 u5 u6 u7)} = (readFloat(),readFloat(),readFloat(),readFloat(),readFloat(),readFloat(),readFloat(),readFloat());
			push @{$sss->{'scale'}},$scale;
		}

	}

	

	#ffd
	if ( my $n = readInt() ) {
		for ( my $i = 0; $i < $n; $i++ ) {
			my $ffd = readString();
			$ss = ( $s->{'ffd'}{$ffd} = {} );
			tie %$ss, 'Tie::IxHash';

			logger("ffd $i/$n, $ffd");
			for ( my ($ii,$nn) = (0,readInt()); $ii < $nn; $ii++ ) {
				my $ffdIndex = readString();
				logger("ffdIndex $ii/$nn, $ffdIndex");
				my $sss = ( $s->{$ffdIndex} = {} );
				tie %$sss, 'Tie::IxHash';
				for ( my ($iii,$nnn) = (0,readInt()); $iii < $nnn; $iii++ ) {
					my $f = readString();
					logger("subffdIndex $iii/$nnn, $f");
					my $frameCount = readInt();
					logger("frameCount: $frameCount");

					for ( my $frameIndex = 0; $frameIndex < $frameCount; $frameIndex++ ) {
						my $ffddata = {};
						tie %$ffddata, 'Tie::IxHash';
						my $time = readFloat();

						my $vertices = [];
						my $end = readInt();

						my $attachment = 'skinnedmesh';
						my $attachment = 'mesh';


						if ( $end == 0 ) {

						} else {
							my $start = readInt();
							$end += $start;
							for ( my $k = $start; $k < $end; $k++ ) {
								readFloat()
							}
						}

						if ( $frameIndex < $frameCount - 1 ) {
							readCurve();
						}

						@$ffddata{qw(time curve un1 un2)} = ($time);
						push @{$ss->{$ffdIndex}{$f}},$ffddata;
					}
				}
			}
		}
	} else {
		logger("NO ffd data");
	}

=cut
	#drawOrder
	$ss = ( $s->{'drawOrder'} = [] );
	for ( my ($i,$n) = (0,readInt()); $i < $n; $i++ ) {
		logger("drawOrder $i/$n");
		my $drawOrder = {};
		tie %$drawOrder, 'Tie::IxHash';
		@$drawOrder{qw(time un1 un2 un3)} = (readFloat(),readInt(),readFloat(),readFloat());
		push @$ss,$drawOrder;
		print STDERR Dumper [$drawOrder,$seek];
	}
=cut

	#events
	if ( my $n = readInt() ) {
		$ss = ( $s->{'events'} = [] );
		for ( my $i = 0; $i < $n; $i++ ) {
			logger("event $i/$n");
			my $event = {};
			tie %$event, 'Tie::IxHash';
			@$event{qw(name time)} = (readString(),readFloat());
			push @$ss,$event;
		}
	} else {
		logger("NO events data");
	}


}

sub parseCurve {
	for ( shift ) {
		$_ == 0 && return "linear";
		$_ == 1 && return "stepped";
		$_ == 2 && return "bezier";
		read $fh, my($data), 1024;
		die "[$seek]\n";
	}
}

sub readSkin {
	my $skel = shift;
	my $skinName = shift;
	my $s = ($skel->{$skinName} = {});
	tie %$s, 'Tie::IxHash';

	for ( my ($i,$n) = (0,readInt()); $i < $n; $i++ ) {
		my $name = readString();
		my $ss = ( $s->{$name} = {} );
		logger("skinIndex: $i/$n ($name)");
		for ( my ($ii,$nn) = (0,readInt());$ii < $nn; $ii++ ) {
			logger("slotIndex: $ii/$nn");
			readAttachment($ss,$name);
		}
	}
}

sub readAttachment {
	my $skel = shift;
	my $attachmentName = shift;

	my $name = readString();
	my $type = readInt();
	$name = $attachmentName if $name eq '';

	logger("name: $name");

	for ( $type ) {
		$_ == region && do {
			logger("region");
			my $path = readString();
			$path = $name if $path eq '';
			my $region = {};
			tie %$region, 'Tie::IxHash';
#			$region->{'path'} = $path;
			$region->{'x'} = readFloat();
			$region->{'y'} = readFloat();
			$region->{'scaleX'} = readFloat();
			delete($region->{'scaleX'}) if $region->{'scaleX'} == 1;
			$region->{'scaleY'} = readFloat();
			delete($region->{'scaleY'}) if $region->{'scaleY'} == 1;
			$region->{'rotation'} = readFloat();
			delete($region->{'rotation'}) if $region->{'rotation'} == 0;
			$region->{'width'} = readFloat();
			$region->{'height'} = readFloat();

			$region->{'r'} = readInt();
			delete($region->{'r'}) if $region->{'r'} == 0;
			$region->{'g'} = readInt();
			delete($region->{'g'}) if $region->{'g'} == 0;
			$region->{'b'} = readInt();
			delete($region->{'b'}) if $region->{'b'} == 0;
			$region->{'a'} = readInt();
			delete($region->{'a'}) if $region->{'a'} == 0;

			$skel->{$path} = $region;
			last;
		};
		$_ == boundingbox && do {
			logger("boundingbox");
			my $array = readFloatArray();
			$skel->{$name}{'type'} = 'boundingbox';
			$skel->{$name}{'vertices'} = $array;
			last;
		};
		$_ == mesh && do {
			logger("mesh");
			my $path = readString();
			$path = $name if $path eq '';
			my $mesh = {};
			$mesh->{'type'} = 'mesh';
			$mesh->{'uvs'} = readFloatArray();
			readInt();
			$mesh->{'triangles'} = readShortArray();

			readFloat();
			readFloat();
			readFloat();
			readFloat();

			$mesh->{'edges'} = readIntArray();
			$mesh->{'width'} = readFloat();
			$mesh->{'height'} = readFloat();

			$skel->{$name}{$path} = $mesh;
#			logger(Dumper($mesh));
			last;

		};
		$_ == skinnedmesh && do {
			logger("skinnedmesh");
			my $path = readString();
			$path = $name if $path eq '';
			my $mesh = {};
			tie %$mesh, 'Tie::IxHash';
			$mesh->{'type'} = 'skinnedmesh';
			my $uvs = [ map { sprintf("%.5f",$_) + 0 } @{readFloatArray()} ];
			my $triangles = readShortArray();
			my $vertexCount = readInt();
			my $weights = [];
			my $bones = [];

			logger("vertexCount: $vertexCount");

			for ( my $i = 0; $i < $vertexCount; $i++ ) {
				my $boneCount = abs(int(readFloat()));
				#logger("boneCount: $boneCount");
				push @$bones,$boneCount;

#				for ( my $nn = $i + $boneCount * 4; $i < $nn; $i += 4 ) {
#					push @$bones,int(readFloat());
#					push @$weights,readFloat();
#					push @$weights,readFloat();
#					push @$weights,readFloat();
#				}
			}

			my $data = {
				'bones' => $bones,
				'weights' => $weights,
				'triangles' => $triangles,
				'uvs' => $uvs,
			};

			$mesh->{'uvs'} = $uvs;
			$mesh->{'triangles'} = readIntArray();

#			updateUVS($data);


			$mesh->{'r'} = readInt();
			delete($mesh->{'r'}) if $mesh->{'r'} == 0;
			$mesh->{'g'} = readInt();
			delete($mesh->{'g'}) if $mesh->{'g'} == 0;
			$mesh->{'b'} = readInt();
			delete($mesh->{'b'}) if $mesh->{'b'} == 0;
			$mesh->{'a'} = readInt();
			delete($mesh->{'a'}) if $mesh->{'a'} == 0;

			$mesh->{'hull'} = readInt();
			$mesh->{'edges'} = readIntArray();
			$mesh->{'width'} = readFloat();
			$mesh->{'height'} = readFloat();

			$skel->{$name}{$path} = $mesh;
			last;
		};

		exitHandler($type);
	}
}

sub get_skins {
	my $skel = shift;
	my $s = ($skel->{'skins'} = {});
	tie %$s, 'Tie::IxHash';
	for ( my ($i, $n ) = (0, readInt() ); $i < $n; $i++ ) {
		my $name = readString();
		logger("skin: $i ($name)");
		readSkin($s,$name); #default
	}
}

sub get_slots {
	my $skel = shift;
	my $s = ( $skel->{'slots'} = [] );
	my $n = readInt();
	for ( my $i = 0; $i < $n; $i++ ) {
		my $slotData = {};
		tie %$slotData, 'Tie::IxHash';
		$slotData->{'name'} = readString();
		$slotData->{'bone'} = readString();
		logger("slot: $slotData->{'name'}/$slotData->{'bone'}");

		$slotData->{'attachmentName'} = readString();
		delete($slotData->{'attachmentName'}) if $slotData->{'attachmentName'} eq '';
		$slotData->{'color1'} = readFloat();
		delete($slotData->{'color1'}) if $slotData->{'color1'} == 1;
		$slotData->{'color2'} = readFloat();
		delete($slotData->{'color2'}) if $slotData->{'color2'} == 1;
		$slotData->{'color3'} = readFloat();
		delete($slotData->{'color3'}) if $slotData->{'color3'} == 1;
		$slotData->{'color4'} = readFloat();
		delete($slotData->{'color4'}) if $slotData->{'color4'} == 1;
		$slotData->{'color5'} = readInt();
		delete($slotData->{'color5'}) if $slotData->{'color5'} == 0;

		push @$s,$slotData;
	}
}


sub get_bones {
	my $skel = shift;
	my $s = $skel->{'bones'} = [];
	my $n = readInt();
	for ( my $i = 0; $i < $n; $i++ ) {
		my $boneData = {};
		tie %$boneData, 'Tie::IxHash';

		$boneData->{'name'} = readString();
		$boneData->{'parent'} = readString();

		logger("bone: $boneData->{'name'}/$boneData->{'parent'}");

		$boneData->{'length'} = readFloat();
		delete($boneData->{'length'}) if $boneData->{'length'} == 0;

		$boneData->{'x'} = readFloat();
		$boneData->{'y'} = readFloat();

		$boneData->{'rotation'} = readFloat();
		delete($boneData->{'rotation'}) if $boneData->{'rotation'} == 0;
		$boneData->{'scaleX'} = readFloat();
		delete($boneData->{'scaleX'}) if $boneData->{'scaleX'} == 1;
		$boneData->{'scaleY'} = readFloat();
		delete($boneData->{'scaleY'}) if $boneData->{'scaleY'} == 1;
		$boneData->{'inheritScale'} = readBoolean();
		delete($boneData->{'inheritScale'}) if $boneData->{'inheritScale'} == 1;
		$boneData->{'inheritRotation'} = readBoolean();
		delete($boneData->{'inheritRotation'}) if $boneData->{'inheritRotation'} == 1;
		push @$s,$boneData;
	}
}

sub eat_unpack {
	my $template = shift;
	my $eat = template_len($template);

	seek $fh, $seek, 0;
	read $fh, my($data), $eat;

	$seek += $eat;
	return [ unpack($template,$data) ];
}

sub template_len {
   my ($template) = @_;
   my $s = pack $template;
   return length $s;
}

sub readByte { eat_unpack("C")->[0];}
sub readShort { eat_unpack("S")->[0];}
sub readInt { eat_unpack("L")->[0];}
sub readFloat { sprintf("%.2f",eat_unpack("f")->[0]) + 0;}
sub readBoolean { eat_unpack("L")->[0];}
sub readString { eat_unpack("Z32")->[0];}
sub readFloatArray {my $n = shift || readInt();	logger("readFloatArray[$n]"); eat_unpack("f$n");}
sub readIntArray { my $n = shift || readInt();	logger("readIntArray[$n]"); eat_unpack("L$n");}
sub readShortArray { 
	my $n = shift || readInt(); 
	logger("readShortArray[$n]");
	return eat_unpack("L$n");
	my $array = [];
	for ( my $i = 0; $i < $n; $i++ ) {
		$array->[$i] = (readByte() << 8 ) + readByte();
	}
	return $array;
}

sub updateUVS {
	my $mesh = shift;
	my $verticesLenght = @{$mesh->{'_vertices'}};
	my $worldVerticesLenght = int($verticesLenght / 2 * 5);
	my ($u, $v, $width, $height ) = (0,0,1,1);

	for ( my ($i,$w) = (0,3); $i < $verticesLenght; $i += 2, $w += 5 ) {
		$mesh->{'vertices'}[$w] = $u + $mesh->{'_uvs'}[$i] * $width;
		$mesh->{'vertices'}[$w+1] = $v + $mesh->{'_uvs'}[$i+1] * $height;
	}
}

sub logger {
	my $string = shift || 'DEBUG';
	print STDERR "\e[1;31m[$seek] $string \e[m\n" if DEBUG;
}

