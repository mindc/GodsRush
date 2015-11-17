package Event;

use strict;
use warnings;

sub new {
	my ($class, $data) = @_;
	my $self = {
		'data' => $data,
		'intValue' => undef,
		'floatValue' => undef,
		'stringValue' => undef
	};

	return bless $self, $class;
}

sub getInt { shift->{'intValue'};}
sub getFloat { shift->{'floatValue'};}
sub getString { shift->{'stringValue'};}
sub getData { shift->{'data'};}

sub setInt { pop->{'intValue'} = pop;}
sub setFloat { pop->{'floatValue'} = pop;}
sub setString { pop->{'stringValue'} = pop;}

1;