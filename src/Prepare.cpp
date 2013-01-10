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
#include "llvm/Support/InstIterator.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/TypeBuilder.h"
#include "llvm/Type.h"
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

bool Prepare::runOnFunction(Function &F) {
  bool modified = false;
  const Module *M = F.getParent();

  for (inst_iterator I = inst_begin(F), E = inst_end(F); I != E;) {
    Instruction *ins = &*I;
    ++I;
    if (CallInst *CI = dyn_cast<CallInst>(ins)) {
      if (CI->isInlineAsm())
        continue;

      Function *callee = CI->getCalledFunction();
      if (!callee || callee->isIntrinsic())
	continue;

      assert(callee->hasName());
      StringRef name = callee->getName();

      if (name.equals("__assert_fail") ||
	  name.equals("exit") ||
	  name.equals("sprintf") || name.equals("snprintf") ||
	  name.equals("swprintf") ||
	  name.equals("malloc") || name.equals("free") ||
	  name.equals("memset") || name.equals("memcmp") ||
	  name.equals("memcpy") || name.equals("memmove") ||
	  name.equals("kzalloc"))
	continue;

      if (name.startswith("__VERIFIER_") || name.equals("nondet_int") ||
		      name.equals("klee_int")) {
//	errs() << "TADY   " << name << "\n";
	continue;
      }

      if (callee->isDeclaration()) {
	errs() << "removing call to '" << name << "'\n";
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
    "__VERIFIER_nondet_char",
    "__VERIFIER_nondet_short",
    "__VERIFIER_nondet_int",
    "__VERIFIER_nondet_long",
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

#if 0
  for (Module::const_global_iterator I = M.global_begin(), E = M.global_end();
      I != E; ++I) {
    const GlobalVariable *GV = &*I;
    if (GV->isConstant())
      continue;
    GV->dump();
//    errs() << "";
  }
#endif

  for (llvm::Module::iterator I = M.begin(), E = M.end(); I != E; ++I) {
    Function &F = *I;
    if (!F.isDeclaration())
      runOnFunction(F);
  }

  findInitFuns(M);

  return true;
}
