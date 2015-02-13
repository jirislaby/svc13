#ifndef _SYMBIOTIC_
#define _SYMBIOTIC_

/* stdbool.h defines bool as _Bool. */
#define __VERIFIER_nondet_bool __VERIFIER_nondet__Bool

#ifdef __cplusplus
extern "C" {
#endif

/* in the case that somebody forgets to declare it */
extern void __VERIFIER_error(void);
extern void __VERIFIER_assert(int expr);

extern void __assert_fail (__const char *__assertion, __const char *__file,
			   unsigned int __line, __const char *__function);

#ifdef __cplusplus
}
#endif

#endif /* _SYMBIOTIC_ */
