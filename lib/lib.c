// GPLv2

#include <klee/klee.h>

void __VERIFIER_assume(int expr)
{
	klee_assume(expr);
}

#define MAKE_NONDET(type)				\
type __VERIFIER_nondet_ ## type(void)			\
{							\
	type x;						\
	klee_make_symbolic(&x, sizeof(x), # type);	\
	return x;					\
}

MAKE_NONDET(char);
MAKE_NONDET(short);
MAKE_NONDET(int);
MAKE_NONDET(long);

#undef MAKE_NONDET

#define MAKE_NONDET(type)				\
type nondet_ ## type(void)				\
{							\
	return __VERIFIER_nondet_ ## type();		\
}

MAKE_NONDET(char);
MAKE_NONDET(short);
MAKE_NONDET(int);
MAKE_NONDET(long);

#undef MAKE_NONDET

#define MAKE_NONDET(type)				\
type __VERIFIER_nondet_u ## type(void)			\
{							\
	return __VERIFIER_nondet_ ## type();		\
}

MAKE_NONDET(char);
MAKE_NONDET(short);
MAKE_NONDET(int);
MAKE_NONDET(long);

#undef MAKE_NONDET

void *__VERIFIER_nondet_pointer()
{
	return (void *)__VERIFIER_nondet_long();
}

/* these are crippled */

unsigned int __VERIFIER_nondet_u32()
{
	return __VERIFIER_nondet_uint();
}

unsigned int __VERIFIER_nondet_unsigned()
{
	return __VERIFIER_nondet_uint();
}

char *__VERIFIER_nondet_pchar()
{
	return __VERIFIER_nondet_pointer();
}

void *kzalloc(int size, int gfp)
{
	extern void *malloc(size_t size);
	return malloc(size);
}
