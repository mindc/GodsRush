package Animation;

use strict;
use warnings;

sub new {
	my ($class, $name, $timelines, $duration ) = @_;
	my $self = {
		'name' => $name,
		'timelines' => $timelines,
	};
	
	return bless $self, $class;
}

sub getName { shift->{'name'}; }
sub getTimelines { shift->{'timelines'}; }

package CurveTimeline;

use strict;
use warnings;
use constant {
	LINEAR => 0,
	STEPPED => 1,
	BEZIER => 2,
	BEZIER_SEGMENTS => 3,
};
use constant BEZIER_SIZE => BEZIER_SEGMENTS * 2 - 1;
use Data::Dumper;

sub new {
	my ($class, $frameCount) = @_;
	my $self = {
		'curves' => [ (undef) x (($frameCount - 1)* BEZIER_SIZE)  ]
	};
	return bless $self, $class;
}

sub getFrameCount {
	my ($self) = @_;
	return @{$self->{'curves'}} / BEZIER_SIZE + 1;
}

sub setLinear {
	my ($self, $frameIndex) = @_;
	$self->{'curves'}[$frameIndex * BEZIER_SIZE] = LINEAR;
	$self->{'curve'}[$frameIndex] = "linear";
}

sub setStepped {
	my ($self, $frameIndex) = @_;
	$self->{'curves'}[$frameIndex * BEZIER_SIZE] = STEPPED;
	$self->{'curve'}[$frameIndex] = "stepped";
}

sub getCurveType {
	my ($self, $frameIndex) = @_;
	my $index = $frameIndex * BEZIER_SIZE;
	return LINEAR if $index == @{$self->{'curves'}};
	my $type = $self->{'curves'}[$index] || 0;
	return LINEAR if $type == LINEAR;
	return STEPPED if $type == STEPPED;
	return BEZIER;
}

sub getCurveName {
	my ($self, $frameIndex) = @_;
	return $self->{'curve'}[$frameIndex] || 'linear';
}


sub setCurve {
	my ($self, $frameIndex, $cx1, $cy1, $cx2, $cy2 ) = @_;
	$self->{'curve'}[$frameIndex] = [ map { sprintf("%.4f",$_)+0 } $cx1, $cy1, $cx2, $cy2 ];

	my $subdiv1 = 1 / BEZIER_SEGMENTS;
	my $subdiv2 = $subdiv1 * $subdiv1;
	my $subdiv3 = $subdiv2 * $subdiv1;
	my $pre1 = 3 * $subdiv1;
	my $pre2 = 3 * $subdiv2;
	my $pre4 = 6 * $subdiv2;
	my $pre5 = 6 * $subdiv3;
	my $tmp1x = - $cx1 * 2 + $cx2;
	my $tmp1y = - $cy1 * 2 + $cy2;
	my $tmp2x = ($cx1 - $cx2) * 3 + 1;
	my $tmp2y = ($cy1 - $cy2) * 3 + 1;
	my $dfx = $cx1 * $pre1 + $tmp1x * $pre2 + $tmp2x * $subdiv3;
	my $dfy = $cy1 * $pre1 + $tmp1y * $pre2 + $tmp2y * $subdiv3;
	my $ddfx = $tmp1x * $pre4 + $tmp2x * $pre5;
	my $ddfy = $tmp1y * $pre4 + $tmp2y * $pre5;
	my $dddfx = $tmp2x * $pre5;
	my $dddfy = $tmp2y * $pre5; 

	my $i = $frameIndex * BEZIER_SIZE;
	my $curves = $self->{'curves'};
	$curves->[$i++] = BEZIER;

	my $x = $dfx;
	my $y = $dfy;
	for ( my $n = $i + BEZIER_SIZE - 1; $i < $n; $i += 2 ) {
		$curves->[$i] = $x;
		$curves->[$i + 1] = $y;
		$dfx += $ddfx;
		$dfy += $ddfy;
		$ddfx += $dddfx;
		$ddfy += $dddfy;
		$x += $dfx;
		$y += $dfy;
	}
}

sub getCurvePercent {
	my ($self, $frameIndex, $percent ) = @_;
	my $curves = $self->{'curves'};
	my $i = $frameIndex * BEZIER_SIZE;
	my $type = $curves->[$i];
	return $percent if $type == LINEAR;
	return 0 if $type == STEPPED;
	$i++;
	my $x = 0;
	for ( my ($start,$n) = ($i, $i + BEZIER_SIZE - 1); $i < $n; $i += 2 ) {
		$x = $curves->[$i];
		if ( $x >= $percent ) {
			my ($prevX, $prevY);
			if ( $i == $start ) {
				$prevX = 0;
				$prevY = 0;
			} else {
				$prevX = $curves->[$i - 2];
				$prevY = $curves->[$i - 1];
			}
			return $prevY + ($curves->[$i + 1] - $prevY) * ($percent - $prevX) / ($x - $prevX);
		}
		my $y = $curves->[$i - 1];
		return $y + (1 - $y) * ($percent - $x) / (1 - $x);
	}
}

package RotateTimeline;
use base qw(CurveTimeline);

use strict;
use warnings;
use Data::Dumper;
use constant {
	PREV_FRAME_TIME => -2,
	FRAME_VALUE => 1
};

sub new {
	my $timeline = shift->SUPER::new(@_);
	$timeline->{'boneName'} = undef;
	$timeline->{'frames'} = [];
	return $timeline;
}

sub appendStruct {
    my ( $self, $ref ) = @_;
    for ( my ($i, $n) = (0, $self->getFrameCount()); $i < $n; $i += 2 ) {
        my $o = {};
        tie %$o, 'Tie::IxHash';
		tie %{$ref->{'bones'}{$self->getBoneName()}}, 'Tie::IxHash' unless exists $ref->{'bones'}{$self->getBoneName()};
        $o->{'time'} = sprintf("%.4f", $self->{'frames'}[$i])+0;
        $o->{'angle'} = sprintf("%.2f", $self->{'frames'}[$i+1])+0;
		$o->{'curve'} = $self->getCurveName($i/2) if $self->getCurveName($i/2) ne 'linear';
        push @{$ref->{'bones'}{$self->getBoneName()}{'rotate'}},$o;
    }
}

sub getFrameCount { scalar @{shift->{'frames'}}; }
sub setBoneName { pop->{'boneName'} = pop;}
sub getBoneName { shift->{'boneName'};}
sub getFrames { shift->{'frames'};}

sub setFrame {
	my ($self, $frameIndex, $time, $angle) = @_;
	$frameIndex *= 2;
	$self->{'frames'}[$frameIndex] = $time;
	$self->{'frames'}[$frameIndex + 1] = $angle;
}

sub apply {
	my ($self, $skeleton, $lastTime, $time, $events, $alpha ) = @_;
	my $frames = $self->{'frames'};
	return if $time < $frames->[0];
	
	my $bone = $skeleton->getBone($self->{'boneName'});
	die;
#	if ( $time >= $frames->[@$frames - 2] ) {
#		my $amount = $bone
}

package TranslateTimeline;
use base qw(CurveTimeline);
use strict;
use warnings;
use constant {
	PREV_FRAME_TIME => -3,
	FRAME_X => 1,
	FRAME_Y => 2
};
use Data::Dumper;

sub new {
	my $timeline = shift->SUPER::new(@_);
	$timeline->{'boneName'} = undef;
	$timeline->{'frames'} = [];
	$timeline->{'curve'} = undef;
	return $timeline;
}

sub appendStruct {
    my ( $self, $ref ) = @_;
    for ( my ($i, $n) = (0, $self->getFrameCount()); $i < $n; $i += 3 ) {
        my $o = {};
        tie %$o, 'Tie::IxHash';
		tie %{$ref->{'bones'}{$self->getBoneName()}}, 'Tie::IxHash' unless exists $ref->{'bones'}{$self->getBoneName()};

        $o->{'time'} = sprintf("%.4f", $self->{'frames'}[$i])+0;
        $o->{'x'} = sprintf("%.2f", $self->{'frames'}[$i+1])+0;
        $o->{'y'} = sprintf("%.2f", $self->{'frames'}[$i+2])+0;
		$o->{'curve'} = $self->getCurveName($i/3) if $self->getCurveName($i/3) ne 'linear';
        push @{$ref->{'bones'}{$self->getBoneName()}{'translate'}},$o;
    }
}

sub getFrameCount { scalar @{shift->{'frames'}};}
sub setBoneName { pop->{'boneName'} = pop;}
sub getBoneName { shift->{'boneName'};}
sub getFrames { shift->{'frames'};}

sub setFrame {
	my ($self, $frameIndex, $time, $x, $y) = @_;
	$frameIndex *= 3;
	my $frames = $self->{'frames'};
	$frames->[$frameIndex] = $time;
	$frames->[$frameIndex + 1] = $x;
	$frames->[$frameIndex + 2] = $y;
}

package ScaleTimeline;
use base qw(TranslateTimeline);
use strict;
use warnings;

sub new {
	my $timeline = shift->SUPER::new(@_);
	$timeline->{'curve'} = undef;
	return $timeline;
}

sub appendStruct {
    my ( $self, $ref ) = @_;
    for ( my ($i, $n) = (0, $self->getFrameCount()); $i < $n; $i += 3 ) {
        my $o = {};
        tie %$o, 'Tie::IxHash';
		tie %{$ref->{'bones'}{$self->getBoneName()}}, 'Tie::IxHash' unless exists $ref->{'bones'}{$self->getBoneName()};

        $o->{'time'} = sprintf("%.4f", $self->{'frames'}[$i])+0;
        $o->{'x'} = sprintf("%.3f", $self->{'frames'}[$i+1])+0;
        $o->{'y'} = sprintf("%.3f", $self->{'frames'}[$i+2])+0;
		$o->{'curve'} = $self->getCurveName($i/3) if $self->getCurveName($i/3) ne 'linear';
        push @{$ref->{'bones'}{$self->getBoneName()}{'scale'}},$o;
    }
}



package ColorTimeline;
use base qw(CurveTimeline);

use strict;
use warnings;
use constant {
	PREV_FRAME_TIME => -5,
	FRAME_R => 1,
	FRAME_G => 2,
	FRAME_B => 3,
	FRAME_A => 4
};

sub new {
	my $timeline = shift->SUPER::new(@_);
	$timeline->{'frames'} = [];
	return $timeline;
}


sub appendStruct {
    my ( $self, $ref ) = @_;
    for ( my ($i, $n) = (0, $self->getFrameCount()); $i < $n; $i += 5 ) {
        my $o = {};
        tie %$o, 'Tie::IxHash';
		tie %{$ref->{'slots'}{$self->getSlotName()}}, 'Tie::IxHash' unless exists $ref->{'slots'}{$self->getSlotName()};
        $o->{'time'} = sprintf("%.4f", $self->{'frames'}[$i])+0;
        $o->{'color'} = sprintf("%02x%02x%02x%02x",255*$self->{'frames'}[$i+1],255*$self->{'frames'}[$i+2],255*$self->{'frames'}[$i+3],255*$self->{'frames'}[$i+4]);
		$o->{'curve'} = $self->getCurveName($i/5) if $self->getCurveName($i/5) ne 'linear';
        push @{$ref->{'slots'}{$self->getSlotName()}{'color'}},$o;
    }
}

sub getFrameCount { scalar @{shift->{'frames'}};}
sub setSlotName { pop->{'slotName'} = pop;}
sub getSlotName { shift->{'slotName'};}
sub getFrames { shift->{'frames'};}
sub setFrame {
	my ( $self, $frameIndex, $time, $r, $g, $b, $a) = @_;
	$frameIndex *= 5;
	my $frames = $self->{'frames'};
	$frames->[$frameIndex] = $time;
	$frames->[$frameIndex + 1] = $r;
	$frames->[$frameIndex + 2] = $g;
	$frames->[$frameIndex + 3] = $b;
	$frames->[$frameIndex + 4] = $a;
}

sub clamp {
	my ( $value, $min, $max ) = @_;
	return $value > $max ? $max : $value < $min ? $min : $value;
}

sub apply {
	my ($self, $skeleton, $lastTime, $time, $events, $alpha) = @_;
	my $frames = $self->{'frames'};
	return if $time < $frames->[0];
	my ($r, $g, $b, $a);
	if ( $time >= $frames->[@$frames - 5] ) {
		my $i = @$frames - 1;
		$r = $frames->[$i - 3];
		$g = $frames->[$i - 2];
		$b = $frames->[$i - 1];
		$a = $frames->[$i];
	} else {
		my $frameIndex = binarySearch($frames, $time, 5);
		my $prevFrameR = $frames->[$frameIndex - 4];
		my $prevFrameG = $frames->[$frameIndex - 3];
		my $prevFrameB = $frames->[$frameIndex - 2];
		my $prevFrameA = $frames->[$frameIndex - 1];
		my $frameTime = $frames->[$frameIndex];

		my $percent = clamp(1 - ($time - $frameTime) / ($frames->[$frameIndex + PREV_FRAME_TIME] - $frameTime), 0, 1);
		$percent = $self->getCurvePErcent($frameIndex / 5 - 1, $percent);
		$r = $prevFrameR + ($frames->[$frameIndex + FRAME_R] - $prevFrameR) * $percent;
		$g = $prevFrameG + ($frames->[$frameIndex + FRAME_G] - $prevFrameG) * $percent;
		$b = $prevFrameB + ($frames->[$frameIndex + FRAME_B] - $prevFrameB) * $percent;
		$a = $prevFrameA + ($frames->[$frameIndex + FRAME_A] - $prevFrameA) * $percent; 
	}
	my $color = $skeleton->getSlot($self->{'slotIndex'})->{'color'};
	if ( $alpha < 1 ) {
		die;
		$color;
	} else {
		$color->set($r, $g, $b, $a);
	}
}

package EventTimeline;
use base qw(CurveTimeline);

use strict;
use warnings;

sub new {
	my $timeline = shift->SUPER::new(@_);
	$timeline->{'frames'} = [];
	$timeline->{'events'} = [];
	return $timeline;
}

sub appendStruct {
    my ( $self, $ref ) = @_;
    for ( my ($i, $n) = (0, $self->getFrameCount()); $i < $n; $i += 1 ) {
        my $o = {};
        tie %$o, 'Tie::IxHash';
        $o->{'time'} = sprintf("%.4f", $self->{'frames'}[$i])+0;
        $o->{'name'} = $self->{'events'}[$i]->getData()->getName();
        push @{$ref->{'events'}},$o;
    }
}


sub getFrameCount {	scalar @{shift->{'frames'}};}
sub getFrames { shift->{'frames'}; }
sub getEvents { shift->{'events'}; }

sub setFrame {
	my ($self, $frameIndex, $time, $event) = @_;
	$self->{'frames'}[$frameIndex] = $time;
	$self->{'events'}[$frameIndex] = $event;
}

package FfdTimeline;
use base qw(CurveTimeline);

use strict;
use warnings;
use Data::Dumper;

sub new {
	my $timeline = shift->SUPER::new(@_);
	$timeline->{'frames'} = [];
	$timeline->{'frameVertices'} = [];
	$timeline->{'slotName'} = undef;
	$timeline->{'attachment'} = undef;
	$timeline->{'curve'} = [];
	return $timeline;
}

sub appendStruct {
    my ( $self, $ref ) = @_;
    tie %{$ref->{$self->getSlotName()}}, 'Tie::IxHash' unless exists $ref->{$self->getSlotName()};
   	$ref->{$self->getSlotName()}{$self->getAttachment()->getName()} = [];
    for ( my ($i, $n) = (0, $self->getFrameCount()); $i < $n; $i += 1 ) {
        my $o = {};
        tie %$o, 'Tie::IxHash';
        $o->{'time'} = sprintf("%.4f", $self->{'frames'}[$i])+0;
        $o->{'curve'} = 'stepped' if $i == 0 && $n > 1;#$self->getCurveName($i) if $self->getCurveName($i) ne 'linear';
        push @{$ref->{$self->getSlotName()}{$self->getAttachment()->getName()}},$o;
    }
}

sub setSlotName { pop->{'slotName'} = pop;}
sub getSlotName { shift->{'slotName'};}	
sub setAttachment { pop->{'attachment'} = pop;}
sub getAttachment { shift->{'attachment'}; }
sub getFrames { shift->{'frames'};}
sub getVertices { shift->{'frameVertices'};}
sub setFrame {
	my ($self, $frameIndex, $time, $vertices) = @_;
	$self->{'frames'}[$frameIndex] = $time;
	$self->{'frameVertices'}[$frameIndex] = $vertices;
}


package AttachmentTimeline;
use base qw(CurveTimeline);

use strict;
use warnings;
use Tie::IxHash;

sub new {
	my $timeline = shift->SUPER::new(@_);
	$timeline->{'slotName'} = undef;
	$timeline->{'frames'} = [];
	$timeline->{'attachmentNames'} = [];
	return $timeline;
}

sub getFrameCount { scalar @{shift->{'frames'}};}
sub getSlotName { shift->{'slotName'};}
sub setSlotName { pop->{'slotName'} = pop; }
sub getFrames { shift->{'frames'}; }
sub getAttachmentNames { shift->{'attachmentNames'}; }

sub setFrame {
	my ( $self, $frameIndex, $time, $attachmentName ) = @_;
	$self->{'frames'}[$frameIndex] = $time;
	$self->{'attachmentNames'}[$frameIndex] = $attachmentName;	
}

sub appendStruct {
	my ( $self, $ref ) = @_;
	for ( my ($i, $n) = (0, $self->getFrameCount()); $i < $n; $i++ ) {
		my $o = {};
		tie %$o, 'Tie::IxHash';
		tie %{$ref->{'slots'}{$self->getSlotName()}}, 'Tie::IxHash' unless exists $ref->{'slots'}{$self->getSlotName()};
		$o->{'time'} = sprintf("%.4f", $self->{'frames'}[$i])+0;
		$o->{'name'} = $self->{'attachmentNames'}[$i] || undef;
        $o->{'curve'} = $self->getCurveName($i) if $self->getCurveName($i) ne 'linear';
		push @{$ref->{'slots'}{$self->getSlotName()}{'attachment'}},$o;
	}
}


sub apply {
	my ( $self, $skeleton, $lastTime, $time, $events, $alpha) = @_;
	my $frames = $self->{'frames'};

	if ( $time < $frames->[0] ) {
		$self->apply($skeleton, $lastTime, (1 << 32) - 1, [], 0) if $lastTime > $time;
		return;
	} elsif ( $lastTime > $time ) {
		$lastTime = -1;
	}

	my $frameIndex = ( $time >= $frames->[-1] ? scalar @$frames : Animation::binarySearch($frames,$time)) - 1;
	return if $frames->[$frameIndex] < $lastTime;

	my $attachmentName = $self->{'attachementNames'}[$frameIndex];
	$skeleton->getSlot($self->{'slotName'}).setAttachment(
		$attachmentName == '' ? '' : $skeleton.getAttachment($self->{'slotName'}, $attachmentName));
}

1;
 