#!/bin/sh

if echo "$1" | grep -q '\.set$'; then
	FILES=`cat "$1"`
else
	FILES="$1"
fi

test -z "$CLANG_WARNS" && CLANG_WARNS=-w
test -z "$KLEE" && KLEE=klee
test -z "$KLEE_PARAMS" && KLEE_PARAMS="-max-stp-time=5 -max-time=600"
test -z "$LIB" && LIB="`dirname $0`/../lib/lib.c"
test -z "$LIBo" && LIBo="${LIB%.c}.o"
test -z "$MFLAG" && MFLAG=-m32
test -n "$KLEE_DIR" && LIB_CFLAGS="$LIB_CFLAGS -I${KLEE_DIR}/include"

if [ ! -f "$LIB" ]; then
	echo "no lib at '$LIB' => no cookie for you"
	exit 1
fi

if [ ! -f "$LIBo" -o "$LIBo" -ot "$LIB" ]; then
	clang -Wall "$MFLAG" -g -c -emit-llvm -O0 $LIB_CFLAGS -o "$LIBo" "$LIB" || exit 1
fi

build_one() {
	OUT="${FILE%.c}.o"
	echo "$OUT"

	test -f "$OUT" -a "$OUT" -nt "$FILE" -a "$OUT" -nt "$LIBo" && return
	echo "$FILE => $OUT" >&2
	clang -c -g -x c "$MFLAG" -emit-llvm -include /usr/include/assert.h $CLANG_WARNS -O0 -o "${FILE%.c}.llvm" "$FILE" || exit 1
	opt -load LLVMsvc13.so -prepare "${FILE%.c}.llvm" -o "${FILE%.c}.prepared" || exit 1
	if [ -n "$SLICE" ]; then
		opt -load LLVMSlicer.so -simplifycfg -create-hammock-cfg -slice-inter -simplifycfg "${FILE%.c}.prepared" -o "${FILE%.c}.sliced" || return
	else
		mv "${FILE%.c}.prepared" "${FILE%.c}.sliced"
	fi
	llvm-link -o "$OUT" "${FILE%.c}.sliced" "$LIBo" || exit 1
	rm -f "${FILE%.c}.sliced" "${FILE%.c}.prepared" "${FILE%.c}.llvm"
}

for FILE in $FILES; do
	OUT=`build_one "$FILE"` || exit 1
#	echo "$KLEE $KLEE_PARAMS: $FILE" >&2
	$KLEE $KLEE_PARAMS -output-dir="$OUT-klee-out" "$OUT" || exit 1
done
