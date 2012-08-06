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

#undef MAKE_NONDET

#define MAKE_NONDET(type)				\
type nondet_ ## type(void)				\
{							\
	return __VERIFIER_nondet_ ## type();		\
}

MAKE_NONDET(char);
MAKE_NONDET(short);
MAKE_NONDET(int);

#undef MAKE_NONDET
