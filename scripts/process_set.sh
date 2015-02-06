#!/bin/sh

if [ "x$DEBUG" != "x" ]; then
	set -x
fi

if echo "$1" | grep -q '\.set$'; then
	FILES=`cat "$1"`
else
	FILES="$1"
fi

DIR="`dirname $0`"

test -z "$CLANG_WARNS" && CLANG_WARNS=-w
test -z "$KLEE" && KLEE="$DIR/bin/klee"
test -z "$KLEE_PARAMS" && KLEE_PARAMS="-max-solver-time=5 -max-time=600"
test -z "$MFLAG" && MFLAG="-m32"
test -z "$LIB" && LIB="$DIR/lib.c"
test -z "$LIBo" && LIBo="${LIB%.c}.o"

LIB_CFLAGS="$LIB_CFLAGS -I${DIR}/include"

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

	clang -c -g -x c $MFLAG -include $DIR/include/symbiotic.h -emit-llvm $CLANG_WARNS -O0 -o "${FILE%.c}.llvm" "$FILE" || exit 1
	opt -load LLVMsvc13.so -prepare "${FILE%.c}.llvm" -o "${FILE%.c}.prepared" || exit 1

	if [ "x$SLICE" = "x1" ]; then
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
