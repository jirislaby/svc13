#!/bin/sh

if echo "$1" | grep -q '\.set$'; then
	FILES=`cat "$1"`
else
	FILES="$1"
fi

for FILE in $FILES; do
	sed -i -e '
	s@__VERIFIER_assert(\(.*\),.*).*@ __VERIFIER_assert(\1);@;
	s@ERROR:\s*goto ERROR;@ERROR: __VERIFIER_error();@;
	s@ERROR:@ERROR: __VERIFIER_error(); __VERIFIER_error();@' "$FILE"
done
