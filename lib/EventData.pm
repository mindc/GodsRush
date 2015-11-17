package EventData;

use strict;
use warnings;

sub new {
	my ($class, $name ) = @_;
	my $self = {
		'name' => $name,
		'intValue' => undef,
		'floatValue' => undef,
		'stringValue' => undef
	};
	return bless $self, $class;
}

sub getInt { shift->{'intValue'};}
sub getFloat { shift->{'floatValue'};}
sub getString { shift->{'stringValue'};}
sub getName { shift->{'name'};}

sub setInt { pop->{'intValue'} = pop;}
sub setFloat { pop->{'floatValue'} = pop;}
sub setString { pop->{'stringValue'} = pop;}

1;


