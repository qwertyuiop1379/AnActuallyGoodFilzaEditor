ARCHS = arm64
TARGET = iphone:clang:11.2:11.0
GO_EASY_ON_ME = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AnActuallyGoodFilzaEditor
AnActuallyGoodFilzaEditor_FILES =  $(wildcard Source/*.x Source/*.xm)
AnActuallyGoodFilzaEditor_CFLAGS += -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Filza"
