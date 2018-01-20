PACKAGE_VERSION = 0.0.2.1
TARGET = iphone:clang:11.2:7.0
ARCHS = armv7 armv7s arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Amber
Amber_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = Amber
Amber_FILES = Switch.xm
Amber_LIBRARIES = flipswitch
Amber_FRAMEWORKS = UIKit
Amber_INSTALL_PATH = /Library/Switches

include $(THEOS_MAKE_PATH)/bundle.mk
