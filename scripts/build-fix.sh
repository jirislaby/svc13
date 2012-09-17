#!/bin/sh

SET=$1

for FILE in `cat "$SET"`; do
	sed -i	-e '
	s@^long __builtin_expect(long val , long res ) $@long s__builtin_expect(long val , long res ) @;
	s@^void assert(int i ) $@void sassert(int i)@;
	s@^void \*__builtin_memcpy(void \* , void[ const]*\* , unsigned long *) *;$@@;
	s@^unsigned long __builtin_object_size(void \* , int *) ;$@@;
	s@^long __builtin_expect(long , long ) ;$@@;
	s@^void __builtin_prefetch(void const *\* *, \.\.\.) ;@@;
	s@^void __builtin_va_start(__builtin_va_list *) ;$@@;
	s@^void __builtin_va_end(__builtin_va_list *) ;$@@;
	s@^void \*__builtin_alloca(unsigned [longit]* *) ;$@@;
	s@__builtin_va_start(\(.*\));@va_start(\1);@;
	s@\(int __VERIFIER_nondet_int()\) { int x; return x; }@extern \1;@' \
		"$FILE"
done
