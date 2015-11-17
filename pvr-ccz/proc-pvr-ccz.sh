#!/bin/bash

WORKDIR=`pwd`
DATADIR=`realpath $1`

for i in `find $DATADIR -name "*.pvr.ccz" -print`;do
	target=${i%.*.*}
	echo $target
	mkdir -p $target
	cd $target
	cd ..
	TexturePacker $target.pvr.ccz --sheet $target.png --no-trim --algorithm Basic --png-opt-level 0 --shape-padding 0 --border-padding 0 --padding 0 --inner-padding 0 --allow-free-size
	cd $target
	$WORKDIR/plist.pl $target.plist $target.png
done

