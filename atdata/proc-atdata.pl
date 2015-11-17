#!/usr/bin/perl

use strict;
use warnings;
use lib qw(../lib);
use AtlasAttachmentLoader;
use TextureAtlas;
use JSON::XS;
use File::Basename;

my ($name, $path, $suffix) = fileparse($ARGV[0],'.atdata');
my $atlas = TextureAtlas->new();
$atlas->readBinary("$path$name$suffix");

open my $fh, ">", "$path$name.atlas";
print $fh $atlas->save();
close $fh;

mkdir "$path$name";
for ( my ($i, $n) = (0, scalar @{$atlas->{'textures'}}); $i < $n; $i++) {
	my $tex = $atlas->{'textures'}[$i];
	foreach my $region ( @{$atlas->{'regions'}} ) {
		if ( $i == $region->getTextureIndex() ) {
			if ( $region->getRotate() ) {
				system sprintf "convert '%s%s' -crop %dx%d+%d+%d -rotate 90 '%s/%s.png'\n", $path,$tex->{'filename'},$region->getHeight(),$region->getWidth(),$region->getX(),$region->getY(),"$path$name",$region->getName();
			} else {
				system sprintf "convert '%s%s' -crop %dx%d+%d+%d '%s/%s.png'\n", $path,$tex->{'filename'},$region->getWidth(),$region->getHeight(),$region->getX(),$region->getY(),"$path$name",$region->getName();	
			}
		}
	}
}
