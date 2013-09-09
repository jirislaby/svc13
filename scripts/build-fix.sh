#!/bin/sh

if echo "$1" | grep -q '\.set$'; then
	FILES=`cat "$1"`
else
	FILES="$1"
fi

for FILE in $FILES; do
	sed -i	-e '
	s@__inline_*@@;
	s@^long __builtin_expect(long val , long res ) $@long s__builtin_expect(long val , long res ) @;
	s@^ *void assert(int i *) *$@void sassert(int i)@;
	s@^void assert(int cond) {$@void sassert(int cond) {@;
	s@^void \*__builtin_memcpy(void \* , void[ const]*\* , unsigned long *) *;$@@;
	s@^unsigned long __builtin_object_size(void \* , int *) ;$@@;
	s@^long __builtin_expect(long , long ) ;$@@;
	s@^void __builtin_prefetch(void const *\* *, \.\.\.) ;@@;
	s@^void \*__builtin_alloca(unsigned [longit]* *) ;$@@;
	s@^\([a-z_ *]* __VERIFIER_nondet_[a-z_]*()\) { [a-z_ *]* [a-z_]*; return [a-z_]*; }@extern \1;@;
	s@__builtin_va_start(\(.*\))@va_start(\1)@;
	s@__builtin_va_end(\(.*\))@va_end(\1)@;
	s@^\(int __VERIFIER_nondet_int()\) {$@\1; int bubak() {@' \
		"$FILE"
done
