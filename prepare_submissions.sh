#!/bin/bash

FILES=".gitignore */.gitignore audio/coeffs/*.csv";

if [ ! -d .git ]; then
	echo "Warning: there appears to be no git repository here";
else
	FILES="$FILES .git";
fi

WANTED="makefile audio/makefile audio/passthrough.c audio/print_audio.c audio/signal_generator.c audio/fir_filter.c audio/merge.c";
WANTED="${WANTED} audio/corrupter.sh audio/all_firs_direct.sh audio/all_firs_staged.sh";
WANTED="${WANTED} audio/mp3_file_src.sh audio/mp3_file_src.sh audio/audio_sink.sh audio/all_firs_staged.sh";

for W in $WANTED; do
	if [ ! -f $W ]; then
		echo "Warning: no file called $W";
	else
		FILES="${FILES} ${W}";
	fi
done

tar -czf hpce_cw2_${USER}.tar.gz $FILES;
