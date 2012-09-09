#!/bin/sh

SET=$1

for FILE in `cat "$SET"`; do
	sed -i -e '
	s@^\s*\<ERROR:[ ;]*$@& assert(0);@;
	s@^\s*\<ERROR: *return@ERROR: assert(0); return@;
	s@^\s*{* *ERROR: goto ERROR; *}*\s*$@{ ERROR: assert(0); goto ERROR; }@;
	s@^\s*\(if (.*)\) ERROR: goto ERROR;;*\s*$@\1 { ERROR: assert(0); goto ERROR; }@;
	s@;\s*\<ERROR:@& assert(0);@' "$FILE"
done
