//===-- klee.h --------------------------------------------------*- C++ -*-===//
//
//                     The KLEE Symbolic Virtual Machine
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This is stripped version for Symbiotic tool

#ifndef __KLEE_H__
#define __KLEE_H__

typedef unsigned int size_t;
typedef unsigned long uintptr_t;

#ifdef __cplusplus
extern "C" {
#endif

  void klee_make_symbolic(void *addr, size_t nbytes, const char *name);

  /* The following intrinsics are primarily intended for internal use
     and may have peculiar semantics. */

  void klee_assume(uintptr_t condition);

  __attribute__((noreturn))
  void klee_abort(void);


  /* declare __assert_fail */
  extern void __assert_fail (__const char *__assertion, __const char *__file,
			     unsigned int __line, __const char *__function);

  /* special klee assert macro. this assert should be used when path consistency
   * across platforms is desired (e.g., in tests).
   * NB: __assert_fail is a klee "special" function
   */
# define klee_assert(expr)                                              \
  ((expr)                                                               \
   ? (void) (0)                                                         \
   : __assert_fail (#expr, __FILE__, __LINE__, __PRETTY_FUNCTION__))    \

#ifdef __cplusplus
}
#endif

#endif /* __KLEE_H__ */
