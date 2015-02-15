#!/bin/sh

if echo "$1" | grep -q '\.set$'; then
	FILES=`cat "$1"`
else
	FILES="$1"
fi

for FILE in $FILES; do
	sed -i -e '
	s@^\s*\<ERROR:[ ;]*$@& __VERIFIER_error();@;
	s@^\s*\<ERROR: *return@ERROR: __VERIFIER_error(); return@;
	s@^\s*{* *ERROR: goto ERROR; *}*\s*$@{ ERROR: __VERIFIER_error(); goto ERROR; }@;
	s@^\s*\(if (.*)\) ERROR: goto ERROR;;*\s*$@\1 { ERROR: __VERIFIER_error(); goto ERROR; }@;
	s@;\s*\<ERROR:@& __VERIFIER_error();@' "$FILE"
done
