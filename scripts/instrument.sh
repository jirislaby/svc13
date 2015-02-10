#!/bin/sh

if echo "$1" | grep -q '\.set$'; then
	FILES=`cat "$1"`
else
	FILES="$1"
fi

for FILE in $FILES; do
	sed -i -e '
	s@^\s*\<ERROR:[ ;]*$@& __assert_fail("Assertion failed", __FILE__, __LINE__, __func__);@;
	s@^\s*\<ERROR: *return@ERROR: __assert_fail("Assertion failed", __FILE__, __LINE__, __func__); return@;
	s@^\s*{* *ERROR: goto ERROR; *}*\s*$@{ ERROR: __assert_fail("Assertion failed", __FILE__, __LINE__, __func__); goto ERROR; }@;
	s@^\s*\(if (.*)\) ERROR: goto ERROR;;*\s*$@\1 { ERROR: __assert_fail("Assertion failed", __FILE__, __LINE__, __func__); goto ERROR; }@;
	s@^\(void __VERIFIER_assert(int expression, char\* x) {\) if (!expression) { ERROR: goto ERROR; }; return; }$@\1 do { if (!expresion) __assert_fail("Assertion failed", __FILE__, __LINE__, __func__);}while(0); }@;
	s@^\(extern void __VERIFIER_error()\).*;@\1 { __assert_fail("Assertion failed", __FILE__, __LINE__, __func__);}@;
	s@;\s*\<ERROR:@& __assert_fail("Assertion failed", __FILE__, __LINE__, __FUNCTION__);@' "$FILE"
done
