#!/usr/bin/perl

use strict;
use warnings;
use Mac::PropertyList qw(:all);

my $data  = parse_plist_file( $ARGV[0] );
my $plist = $data->as_perl;

foreach my $filename ( keys %{$plist->{'frames'}} ) {
	print STDERR "$filename\n";
	my $cmd = parse_data($plist->{'frames'}{$filename});
	print STDERR "convert png:'$ARGV[1]' " . $cmd . " png:'$filename'\n";
    system("convert png:'$ARGV[1]' " . $cmd . " png:'$filename'");
}

sub parse_data {
    my $data = shift;
	my $cmd = '';

    my ($top,$left,$x,$y) = $data->{'frame'} =~ m/\{\{(\d+),(\d+)\},\{(\d+),(\d+)\}\}/;
    my ($o_top,$o_left) = $data->{'offset'} =~ m/\{(-?\d+),(-?\d+)\}/;

	if ( $data->{'rotated'} eq 'true' ) {
		($x,$y) = ($y,$x);
	}

    my ($ss_x,$ss_y) = $data->{'sourceSize'} =~ m/\{(\d+),(\d+)\}/;
    my ($s_top,$s_left,$s_x,$s_y) = $data->{'sourceColorRect'} =~ m/\{\{(\d+),(\d+)\},\{(\d+),(\d+)\}\}/;

	$cmd .= "-crop ${x}x${y}+${top}+${left} ";

	if ( $data->{'rotated'} eq 'true' ) {
		$cmd .= "-rotate '-90' ";
	}

	$cmd .= "-compose Copy -background None -extent ${ss_x}x${ss_y}-${s_top}-${s_left}" . ' ';
    return $cmd;
}
