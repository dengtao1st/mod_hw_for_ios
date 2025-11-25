
#import <dlfcn.h>
#import "HookUtil.h"

void _HookFunction(const char *lib, const char *fun, void *hook, void **old)
{
	void *symbol = dlsym(dlopen(lib, RTLD_LAZY), fun);
	static void (*_MSHookFunction)(void *symbol, void *hook, void **old) = NULL;
	if (_MSHookFunction == NULL) {
		_MSHookFunction = dlsym(dlopen("/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate", RTLD_LAZY), "MSHookFunction");
	}
	if (_MSHookFunction) {
		_MSHookFunction(symbol, hook, old);
	}
	else {
		*old = NULL;
	}
}

void CallMSHookFunction(void *symbol, void *hook, void **old) {
	static void (*_MSHookFunction)(void *symbol, void *hook, void **old) = NULL;
	if (_MSHookFunction == NULL) {
		_MSHookFunction = dlsym(dlopen("/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate", RTLD_LAZY), "MSHookFunction");
	}
	if (_MSHookFunction) {
		_MSHookFunction(symbol, hook, old);
	}
	else {
		*old = NULL;
	}
}

void* CallMSFindSymbol(MSImageRef image, const char *name) {
	static void* (*_MSFindSymbol)(MSImageRef image, const char *name) = NULL;
	if (_MSFindSymbol == NULL) {
		_MSFindSymbol = dlsym(dlopen("/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate", RTLD_LAZY), "MSFindSymbol");
	}
	if (_MSFindSymbol) {
		return _MSFindSymbol(image, name);
	}
	return NULL;
}

MSImageRef CallMSGetImageByName(const char *file) {
	static MSImageRef(*_MSGetImageByName)(const char *file) = NULL;
	if (_MSGetImageByName == NULL) {
		_MSGetImageByName = dlsym(dlopen("/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate", RTLD_LAZY), "MSGetImageByName");
	}
	if (_MSGetImageByName) {
		return _MSGetImageByName(file);
	}
	return NULL;
}

//
void _HookMessage(Class cls, const char *msg, void *hook, void **old)
{
	//
	char name[1024];
	int i = 0;
	do
	{
		name[i] = (msg[i] == '_') ? ':' : msg[i];
	}
	while (msg[i++]);
	SEL sel = sel_registerName(name);

	//
	static void (*_MSHookMessageEx)(Class cls, SEL sel, void *hook, void **old) = NULL;
	if (_MSHookMessageEx == nil)
	{
		_MSHookMessageEx = dlsym(dlopen("/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate", RTLD_LAZY), "MSHookMessageEx");
	}

	//
	if (_MSHookMessageEx)
	{
		_MSHookMessageEx(cls, sel, hook, old);
	}
	else
	{
		*old = method_setImplementation(class_getInstanceMethod(cls, sel), hook);
	}
}
