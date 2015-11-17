package DataInput;

use strict;
use warnings;

our $pos = 0;

sub new {
	my ($class, $fh) = @_;
	my $self = {
		'fh' => $fh,
		'seek' => 0
	};
	return bless $self, $class;
}

sub read {
	my ($self, $eat) = @_;
	my $data;
    $self->{'fh'}->read($data, $eat);
	return $data;
}

sub readFloatArray {
	my $self = shift;
    my $scale = shift || 1;
    my $n = $self->readInt(1);
    my $array = [];
    for ( my $i = 0; $i < $n; $i++ ) {
        $array->[$i] = $self->readFloat() * $scale;
    }
    return $array;
}

sub readByte { 
	my ($self, $unsigned) = @_;
	return $unsigned ? $self->eat_unpack("C")->[0] : $self->eat_unpack("c")->[0];
}

sub readShort { 
	my ($self, $unsigned) = @_;
	return $unsigned ? $self->eat_unpack("S")->[0]: $self->eat_unpack("s")->[0];
}

sub readInt {
	my ($self, $unsigned) = @_;
    return $unsigned ? $self->eat_unpack("L")->[0] : $self->eat_unpack("l")->[0];
}

sub readFloat { 
	return shift->eat_unpack("f")->[0];
}

sub readBoolean { 
	return shift->eat_unpack("L")->[0] > 0 ? 1 : 0;
}

sub readString { 
	return shift->eat_unpack("Z32")->[0];
}

sub readIntArray { 
	my $self = shift;
	my $n = $self->readInt(1); 
	return $self->eat_unpack("L$n");
}

sub tell {
	my $self = shift;
	return $self->{'fh'}->tell;
}

sub eat_unpack {
	my ($self, $template) = @_;
	my $fh = $self->{'fh'};
    my $eat = template_len($template);
    $fh->read(my($data), $eat);
	$pos += $eat;
    return [ unpack($template,$data) ];
}

sub template_len {
   return length pack shift;
}

sub DESTROY {
	shift->{'fh'}->close;
}

1;