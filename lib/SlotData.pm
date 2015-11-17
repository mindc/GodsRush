package SlotData;

use strict;
use warnings;
use Color;
use Tie::IxHash;

sub new {
	my ($class, $name, $boneData ) = @_;
	my $self = {};
	tie %$self, 'Tie::IxHash';
	$self = {
		'name' => $name,
		'boneData' => $boneData,
		'color' => Color->new(1,1,1,1),
		'attachmentName' => undef,
		'blendMode' => undef
	};

	return bless $self, $class;
}

sub getName { shift->{'name'};}
sub getBoneData { shift->{'boneData'};}
sub getColor { shift->{'color'};}
sub setAttachmentName { pop->{'attachmentName'} = pop;}
sub getAttachmentName { shift->{'attachmentName'};}
sub getBlendMode { shift->{'blendMode'};}

1;
