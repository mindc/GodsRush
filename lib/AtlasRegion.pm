package AtlasRegion;
use base qw(TextureRegion);
use strict;
use warnings;


sub new {
	my $region = shift->SUPER::new(@_);
	$region->{'textureIndex'} = 0;
	return $region;
}

sub getTextureIndex { shift->{'textureIndex'}; }
sub setTextureIndex { pop->{'textureIndex'} = pop; }


1;