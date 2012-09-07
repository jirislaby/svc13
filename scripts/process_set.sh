#!/bin/sh

SET=$1

test -z "$KLEE" && KLEE=klee
test -z "$KLEE_PARAMS" && KLEE_PARAMS="-max-stp-time=5 -max-time=600"
test -z "$LIB" && LIB="`dirname $0`/../lib/lib.c"
test -n "$KLEE_DIR" && LIB_CFLAGS="$LIB_CFLAGS -I${KLEE_DIR}/include"

if [ ! -f "$LIB" ]; then
	echo "no lib at '$LIB' => no cookie for you"
	exit 1
fi

LIBo="${LIB%.c}.o"

if [ ! -f "$LIBo" -o "$LIBo" -ot "$LIB" ]; then
	clang -Wall -g -c -emit-llvm -O0 $LIB_CFLAGS -o "$LIBo" "$LIB" || exit 1
fi

build_one() {
	OUT="${FILE%.c}.o"
	echo "$OUT"

	test -f "$OUT" -a "$OUT" -nt "$FILE" -a "$OUT" -nt "$LIBo" && return
	echo "$FILE => $OUT" >&2
	clang -c -g -emit-llvm -include /usr/include/assert.h -w -Wall -Wno-unknown-pragmas -Wno-uninitialized -Wno-unused-label -Wno-unused-variable -O0 -o "${FILE%.c}.llvm" "$FILE" || exit 1
	opt -load LLVMsvc13.so -prepare "${FILE%.c}.llvm" -o "${FILE%.c}.prepared" || exit 1
	llvm-link -o "$OUT" "${FILE%.c}.prepared" "$LIBo" || exit 1
	rm -f "${FILE%.c}.prepared" "${FILE%.c}.llvm"
}

for FILE in `cat "$SET"`; do
	OUT=`build_one "$FILE"` || exit 1
#	echo "$KLEE $KLEE_PARAMS: $FILE" >&2
	$KLEE $KLEE_PARAMS "$OUT" || exit 1
done
