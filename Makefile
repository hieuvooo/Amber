PACKAGE_VERSION = 0.0.1
TARGET = iphone:clang:10.2:10.2
ARCHS = armv7 armv7s arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Amber
Amber_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk
