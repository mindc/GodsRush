package TextureAtlas;
use strict;
use warnings;
use DataInput;
use AtlasRegion;
use Data::Dumper;
use File::Basename;

sub new {
	my ($class) = @_;
	my $self = {
		'textures' => [],
		'regions' => []
	};
	return bless $self, $class;
}

sub readBinary {
	my ($self, $filename) = @_;

	open my $fh, "<", $filename;
	my $input = DataInput->new($fh);

	for ( my ($i, $n) = (0,$input->readInt(1)); $i < $n; $i++ ) {
		my $textureFilename = $input->readString();
		push @{$self->{'textures'}},{
			'filename' => $textureFilename,
		};
		$input->readInt();
		$input->readInt();
		$input->readInt();
		$input->readInt();
		$input->readInt();
	}

	for ( my ( $i, $n) = (0, $input->readInt() ); $i < $n; $i++ ) {
		my $region = AtlasRegion->new($input->readString());
		$region->setTextureIndex($input->readInt());			
		$region->setX($input->readInt());
		$region->setY($input->readInt());
		$region->setWidth($input->readInt(1));
		$region->setHeight($input->readInt(1));

		$region->setU( $input->readFloat() );
		$region->setV( $input->readFloat() );
		$region->setU2( $input->readFloat() );
		$region->setV2( $input->readFloat() );

		$region->setOffsetX($input->readInt());
		$region->setOffsetY($input->readInt());
		$region->setOrigWidth($input->readInt());
		$region->setOrigHeight($input->readInt());
		$region->setIndex($input->readInt());
		$region->setRotate($input->readInt());
		$input->readInt();
		
		push @{$self->{'regions'}},$region;

		@{$self->getTexture( $region->getTextureIndex )}{qw(width height)} = ( $region->getX / $region->getU, $region->getY / $region->getV);
	}
}

sub getTexture {
	my ($self, $textureIndex ) = @_;
	return $self->{'textures'}[$textureIndex];
}

sub findRegion {
    my ($self, $regionName) = @_;
    foreach ( @{$self->{'regions'}} ) {
        return $_ if $_->{'name'} eq $regionName;
    }
    return undef;
}

sub save {
	my ( $self ) = @_;
	my $o = '';
	for ( my ($i, $n) = (0, scalar @{$self->{'textures'}}); $i < $n; $i++ ) {
		my $texture = $self->{'textures'}[$i];
		$o .= "\n";
		$o .= $texture->{'filename'} . "\n";
		$o .= 'size: ' . $texture->{'width'} . ',' . $texture->{'height'} . "\n";
		$o .= "format: RGBA8888\n";
		$o .= "filter: Linear,Linear\n";
		$o .= "repeat: none\n";
		foreach my $r ( @{$self->{'regions'}} ) {
			if ( $i == $r->getTextureIndex() ) {
				$o .= $r->getName() . "\n";
				$o .= "  rotate: " . ($r->getRotate() ? 'true' : 'false') . "\n";
				$o .= "  xy: " . $r->getX() . ',' . $r->getY() . "\n";
				$o .= "  size: " . $r->getWidth() . ',' . $r->getHeight() . "\n";
				$o .= "  orig: " . $r->getOrigWidth() . ',' . $r->getOrigHeight() . "\n";
				$o .= "  offset: " . $r->getOffsetX() . ',' . $r->getOffsetY() . "\n";
				$o .= "  index: " . $r->getIndex() . "\n";
			}
		}
	}
	return $o;
}

1;
