#!/bin/sh

SET=$1

for FILE in `cat "$SET"`; do
	sed -i 's/^\s*\<ERROR:/& assert(0);/' "$FILE"
done
