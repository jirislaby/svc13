set(LLVM_LINK_COMPONENTS core engine)

add_llvm_loadable_module(LLVMsvc13
	Prepare.cpp
)
