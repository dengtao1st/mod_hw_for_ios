OUTDIR				?= bin
MAKEFILE 			:= $(shell pwd)/$(lastword $(MAKEFILE_LIST))
MAKEROOT			:= $(shell dirname $(MAKEFILE))
MAKEPATH 			= $(shell pwd)/$(lastword $(MAKEFILE_LIST))
OS_TARGET			:= iphoneos
PROJECT_BIN			:= mod_hw_for_ios.dylib
PROJECT_MK			:= mod_hw_for_ios_make
PROJECT_PLIST		:= mod_hw_for_ios.plist
PREF_PLIST			:= devices.plist
PROJECT_SRC 		:= $(MAKEROOT)/src/oc_hook/hook.mm
PROJECT_SRC 		:= $(MAKEROOT)/src/cydia_substrate_hook/*.m
PROJECT_SRC 		+= $(MAKEROOT)/src/mobile_gestalt/*.m
PROJECT_SRC 		:= $(filter-out %test.cpp, $(PROJECT_SRC))
PROJECT_INC			:= -I $(MAKEROOT)/src/
PROJECT_INC			+= -I $(MAKEROOT)/src/third_party/
PROJECT_LIBS		:= -lm -lz
M1_CC				:= xcrun -sdk $(OS_TARGET) gcc -arch arm64 -arch arm64e --target=arm64-apple-ios11.0 -fvisibility=hidden -fobjc-call-cxx-cdtors -Wc++11-extensions -DCORECRYPTO_DONOT_USE_TRANSPARENT_UNION -Wc++11-extensions -Wall -Os -Bstatic -lc++ -lc -lSystem_asan -lSystem -Wl, -dead_strip 
LDFLAGS 			:= -Wl,-dead_strip
STRIP 				:= $(shell xcrun --sdk $(OS_TARGET) -f strip) -Sx
LDID 				:= ldid2 -S$(MAKEROOT)/ent.xml
M1_CS 				:= $(shell xcrun --sdk $(OS_TARGET) -f codesign) -f -d -s "Apple Development: 981902529@qq.com (Z6U5D93L4P)"
M1_CS				:= $(shell xcrun --sdk $(OS_TARGET) -f codesign) -f --strict -o runtime --timestamp -s "Apple Development: 981902529@qq.com (Z6U5D93L4P)"
PLUGIN_STRIP 		:= $(shell xcrun --sdk $(OS_TARGET) -f strip) -Sx
FRAMEWORKS 			:= -framework Foundation -framework CoreFoundation -framework Security -framework CFNetwork -framework CoreTelephony -lbsm
IPHONE_HOST 		= 127.0.0.1
IPHONE_PORT 		= 2222
IPHONE_PASS			= 'alpine'

all:$(OUTDIR)/$(PROJECT_MK)

$(OUTDIR):
	mkdir -p $(OUTDIR)

$(OUTDIR)/$(PROJECT_MK): $(PROJECT_SRC) | $(OUTDIR)
	$(M1_CC) -dynamiclib $(PROJECT_INC) $(PROJECT_LIBS) -o $(OUTDIR)/$(PROJECT_MK) $(PROJECT_SRC) $(FRAMEWORKS)
	rm -rf $(OUTDIR)/$(PROJECT_BIN)
	mv $(OUTDIR)/$(PROJECT_MK) $(OUTDIR)/$(PROJECT_BIN)
	$(PLUGIN_STRIP) $(OUTDIR)/$(PROJECT_BIN)
	$(LDID) $(OUTDIR)/$(PROJECT_BIN)
	rm -rf /Users/dengtao/.ssh/known_hosts
	sshpass -p $(IPHONE_PASS) ssh -o "StrictHostKeyChecking=no" root@$(IPHONE_HOST) -p $(IPHONE_PORT) "exit"
	sshpass -p $(IPHONE_PASS) ssh -p$(IPHONE_PORT) root@$(IPHONE_HOST) "rm -f /tmp/$(PREF_PLIST)"
	sshpass -p $(IPHONE_PASS) ssh -p$(IPHONE_PORT) root@$(IPHONE_HOST) "rm -f /Library/MobileSubstrate/DynamicLibraries/$(PROJECT_BIN)"
	sshpass -p $(IPHONE_PASS) ssh -p$(IPHONE_PORT) root@$(IPHONE_HOST) "rm -f /Library/MobileSubstrate/DynamicLibraries/$(PROJECT_PLIST)"
	sshpass -p $(IPHONE_PASS) scp -P $(IPHONE_PORT) $(OUTDIR)/../txt/$(PROJECT_PLIST) root@$(IPHONE_HOST):/Library/MobileSubstrate/DynamicLibraries/$(PROJECT_PLIST)
	sshpass -p $(IPHONE_PASS) scp -P $(IPHONE_PORT) $(OUTDIR)/../txt/$(PREF_PLIST) root@$(IPHONE_HOST):/tmp/$(PREF_PLIST)
	sshpass -p $(IPHONE_PASS) scp -P $(IPHONE_PORT) $(OUTDIR)/$(PROJECT_BIN) root@$(IPHONE_HOST):/Library/MobileSubstrate/DynamicLibraries/$(PROJECT_BIN)
	sshpass -p $(IPHONE_PASS) scp -P $(IPHONE_PORT) $(OUTDIR)/../txt/killall.sh root@$(IPHONE_HOST):/tmp/killall.sh
	sshpass -p $(IPHONE_PASS) ssh -p$(IPHONE_PORT) root@$(IPHONE_HOST) "chmod +x /tmp/killall.sh"
	sshpass -p $(IPHONE_PASS) ssh -p$(IPHONE_PORT) root@$(IPHONE_HOST) "/tmp/killall.sh"
	sshpass -p $(IPHONE_PASS) ssh -p$(IPHONE_PORT) root@$(IPHONE_HOST) "/tmp/killall.sh"
	sshpass -p $(IPHONE_PASS) ssh -p$(IPHONE_PORT) root@$(IPHONE_HOST) "/tmp/killall.sh"
	sshpass -p $(IPHONE_PASS) ssh -p$(IPHONE_PORT) root@$(IPHONE_HOST) "/tmp/killall.sh"
	sshpass -p $(IPHONE_PASS) ssh -p$(IPHONE_PORT) root@$(IPHONE_HOST) "/tmp/killall.sh"
	sshpass -p $(IPHONE_PASS) ssh -p$(IPHONE_PORT) root@$(IPHONE_HOST) "killall -9 backboardd"
	sshpass -p $(IPHONE_PASS) ssh -p$(IPHONE_PORT) root@$(IPHONE_HOST) "killall -9 SpringBoard"