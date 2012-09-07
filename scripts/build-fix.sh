#!/bin/sh

SET=$1

for FILE in `cat "$SET"`; do
	sed -i	-e 's@^long __builtin_expect(long val , long res ) $@long s__builtin_expect(long val , long res ) @' \
		-e 's@^void assert(int i ) $@void sassert(int i)@' \
		-e 's@^void \*__builtin_memcpy(void \* , void    \* , unsigned long  ) ;$@@' \
		-e 's@^unsigned long __builtin_object_size(void \* , int *) ;$@@' \
		-e 's@^long __builtin_expect(long , long ) ;$@@' \
		-e 's@^void __builtin_va_start(__builtin_va_list *) ;$@@' \
		-e 's@void \*__builtin_alloca(unsigned int  ) ;@@' \
		-e 's@__builtin_va_start(\(.*\));@va_start(\1);@' "$FILE"
done
