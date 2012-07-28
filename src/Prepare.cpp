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

      Constant *F_klee_int;
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

      StringRef name = callee->getName();

      if (name.equals("__assert_fail"))
	continue;

      if (name.startswith("__VERIFIER_")) {
//	errs() << "TADY   " << name << "\n";
	continue;
      }

      if (name.equals("__VERIFIER_nondet_int")) {
	BasicBlock::iterator ii(CI);
	ReplaceInstWithInst(CI->getParent()->getInstList(), ii,
	    CallInst::Create(F_klee_int));
	continue;
      }

      if (callee->isDeclaration()) {
	errs() << "removing call to " << callee->getName() << "\n";
	/* or maybe NullValue? */
	CI->replaceAllUsesWith(UndefValue::get(CI->getType()));
	CI->eraseFromParent();
      }
    }
  }
  return modified;
}

bool Prepare::runOnModule(Module &M) {
  LLVMContext &C = M.getContext();
  FunctionType *T_klee_int = FunctionType::get(Type::getInt32Ty(C), false);
  F_klee_int = M.getOrInsertFunction("klee_int", T_klee_int);

  for (llvm::Module::iterator I = M.begin(), E = M.end(); I != E; ++I) {
    Function &F = *I;
    if (!F.isDeclaration())
      runOnFunction(F);
  }

  return true;
}
