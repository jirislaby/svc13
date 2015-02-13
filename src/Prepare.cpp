//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.

#include <assert.h>
#include <cstring>

#include "llvm/BasicBlock.h"
#include "llvm/Constants.h"
#include "llvm/Function.h"
#include "llvm/GlobalVariable.h"
#include "llvm/Instructions.h"
#include "llvm/Module.h"
#include "llvm/Pass.h"
#include "llvm/Type.h"
#include "llvm/TypeBuilder.h"
#include "llvm/Support/InstIterator.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"

using namespace llvm;

namespace {
  class Prepare : public ModulePass {
    public:
      static char ID;

      Prepare() : ModulePass(ID) {}

      virtual bool runOnModule(Module &M);

    private:
      bool runOnFunction(Function &F);
      void findInitFuns(Module &M);
  };
}

static RegisterPass<Prepare> X("prepare", "Prepares the code for svcomp");
char Prepare::ID;

static bool array_match(StringRef &name, const char **array)
{
  for (const char **curr = array; *curr; curr++)
    if (name.equals(*curr))
      return true;
  return false;
}

bool Prepare::runOnFunction(Function &F) {
  static const char *leave_calls[] = {
    "__assert_fail",
    "exit",
    "sprintf",
    "snprintf",
    "swprintf",
    "malloc",
    "free",
    "memset",
    "memcmp",
    "memcpy",
    "memmove",
    "kzalloc",
    NULL
  };

  static const char *unsupported_calls[] = {
    "pthread_create",
    NULL
  };

  bool modified = false;
  const Module *M = F.getParent();

  for (inst_iterator I = inst_begin(F), E = inst_end(F); I != E;) {
    Instruction *ins = &*I;
    ++I;
    if (CallInst *CI = dyn_cast<CallInst>(ins)) {
      if (CI->isInlineAsm())
        continue;

      const Value *val = CI->getCalledValue()->stripPointerCasts();
      const Function *callee = dyn_cast<Function>(val);
      if (!callee || callee->isIntrinsic())
	continue;

      assert(callee->hasName());
      StringRef name = callee->getName();
      if (array_match(name, leave_calls))
	continue;

      if (array_match(name, unsupported_calls)) {
	errs() << "Prepare: call to '" << name << "' is unsupported\n";
	return modified;
      }

      if (name.startswith("__VERIFIER_") || name.equals("nondet_int") ||
		      name.equals("klee_int")) {
//	errs() << "TADY   " << name << "\n";
	continue;
      }

      if (callee->isDeclaration()) {
	errs() << "Prepare: removing call to '" << name << "' (unsound)\n";
	if (!CI->getType()->isVoidTy()) {
//	  CI->replaceAllUsesWith(UndefValue::get(CI->getType()));
	  CI->replaceAllUsesWith(Constant::getNullValue(CI->getType()));
	}
	CI->eraseFromParent();
      }
    }
  }
  return modified;
}

void Prepare::findInitFuns(Module &M) {
  SmallVector<Constant *, 1> initFns;
  Type *ETy = TypeBuilder<void *, false>::get(M.getContext());
  Function *_main = M.getFunction("main");
  assert(_main);

  initFns.push_back(ConstantExpr::getBitCast(_main, ETy));
  ArrayType *ATy = ArrayType::get(ETy, initFns.size());
  new GlobalVariable(M, ATy, true, GlobalVariable::InternalLinkage,
                     ConstantArray::get(ATy, initFns),
                     "__ai_init_functions");
}

bool Prepare::runOnModule(Module &M) {
  static const char *del_body[] = {
    "kzalloc",
    "nondet_int",
    "__VERIFIER_assume",
    "__VERIFIER_assert",
    "__VERIFIER_nondet_pointer",
    "__VERIFIER_nondet_pchar",
    "__VERIFIER_nondet_char",
    "__VERIFIER_nondet_short",
    "__VERIFIER_nondet_int",
    "__VERIFIER_nondet_long",
    "__VERIFIER_nondet_uchar",
    "__VERIFIER_nondet_ushort",
    "__VERIFIER_nondet_uint",
    "__VERIFIER_nondet_ulong",
    "__VERIFIER_nondet_unsigned",
    "__VERIFIER_nondet_u32",
    "__VERIFIER_nondet_float",
    "__VERIFIER_nondet_double",
    "__VERIFIER_nondet_bool",
    "__VERIFIER_nondet__Bool",
    NULL
  };
  LLVMContext &C = M.getContext();

  for (const char **curr = del_body; *curr; curr++) {
    Function *toDel = M.getFunction(*curr);
    if (toDel && !toDel->empty()) {
      errs() << "deleting " << toDel->getName() << '\n';
      toDel->deleteBody();
    }
  }

  for (Module::global_iterator I = M.global_begin(), E = M.global_end();
      I != E; ++I) {
    GlobalVariable *GV = &*I;
    if (GV->isConstant() || GV->hasInitializer())
      continue;
    GV->setInitializer(Constant::getNullValue(GV->getType()->getElementType()));
    errs() << "making " << GV->getName() << " non-extern\n";
  }

  for (llvm::Module::iterator I = M.begin(), E = M.end(); I != E; ++I) {
    Function &F = *I;
    if (!F.isDeclaration())
      runOnFunction(F);
  }

  findInitFuns(M);

  return true;
}
