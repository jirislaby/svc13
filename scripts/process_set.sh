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

# slice by default
test -z "$SLICE" && SLICE="1"

LIB_CFLAGS="$LIB_CFLAGS -I${DIR}/include"

if [ ! -f "$LIB" ]; then
	echo "no lib at '$LIB' => no cookie for you"
	exit 1
fi

# build lib.o
clang -Wall "$MFLAG" -g -c -emit-llvm -O0 $LIB_CFLAGS -o "$LIBo" "$LIB" || exit 1

build_one() {
	FILE="$1"
	EXIT_ON_UNKNOWN="$2"
	OUT="${FILE%.c}.o"
	echo "$OUT"

	test -f "$OUT" -a "$OUT" -nt "$FILE" -a "$OUT" -nt "$LIBo" && return
	echo "$FILE => $OUT" >&2

	clang -c -g -x c $MFLAG -include $DIR/include/symbiotic.h -emit-llvm $CLANG_WARNS -O0 -o "${FILE%.c}.llvm" "$FILE" || exit 1
	opt -load LLVMsvc13.so -prepare "${FILE%.c}.llvm" -o "${FILE%.c}.prepared" 2>"${FILE%.c}.prepare.log" || exit 1
	cat "${FILE%.c}.prepare.log" >&2

	if grep -q 'Prepare: call to .* is unsupported' "${FILE%.c}.prepare.log"; then
		# remove before exit
		rm -f "${FILE%.c}.prepared" "${FILE%.c}.prepare.log"

		echo "$FILE UNKNOWN"
		if [ "x$EXIT_ON_UNKNOWN" = "x1" ]; then
			exit 2
		else
			return
		fi
	fi

	llvm-link -o "${FILE%.c}.linked" "${FILE%.c}.prepared" "$LIBo" || exit 1

	if [ "x$SLICE" = "x1" ]; then
		opt -load LLVMSlicer.so -simplifycfg -create-hammock-cfg -slice-inter -simplifycfg "${FILE%.c}.linked" -o "$OUT" || exit 1
	else
		mv "${FILE%.c}.linked" "$OUT"
	fi

	rm -f "${FILE%.c}.prepared" "${FILE%.c}.prepare.log" "${FILE%.c}.llvm"
}

if [ "`ls "$FILES" | wc -l`" -eq 1 ]; then
	EXIT_ON_UNKNOWN=1
fi

for FILE in $FILES; do
	OUT=`build_one "$FILE" "$EXIT_ON_UNKNOWN"` || exit
#	echo "$KLEE $KLEE_PARAMS: $FILE" >&2
	$KLEE $KLEE_PARAMS -output-dir="$OUT-klee-out" "$OUT" || exit 1
done
