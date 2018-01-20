#import "Header.h"

/*
    This tweak (I call it Amber) can tell the camera to use only the amber LED for torch.
    In normal situations, the camera decides whether to turn on the amber LED if the scene temperature matches.
    Amber tricks the camera into thinking that the scene always matches amber lighting condition.
    When the scene is determined to be the warmest (percentile >= 100), only amber LED will turn on.
*/

typedef struct HXISPCaptureStream *HXISPCaptureStreamRef;
typedef struct HXISPCaptureDevice *HXISPCaptureDeviceRef;

int (*SetTorchLevel)(CFNumberRef, HXISPCaptureStreamRef, HXISPCaptureDeviceRef);
int (*SetTorchColor)(CFMutableDictionaryRef, HXISPCaptureStreamRef, HXISPCaptureDeviceRef);
SInt32 (*GetCFPreferenceNumber)(CFStringRef const, CFStringRef const, SInt32);

%hookf(int, SetTorchLevel, CFNumberRef level, HXISPCaptureStreamRef stream, HXISPCaptureDeviceRef device) {
    int result = %orig(level, stream, device);
    if (!result && level && GetCFPreferenceNumber(key, kDomain, 0)) {
        // If torch level setting is successful, we can override the torch color
        CFMutableDictionaryRef dict = CFDictionaryCreateMutable(NULL, 0, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        int val = 100; // from 0 (coolest) to 100 (warmest)
        CFNumberRef threshold = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &val);
        CFDictionaryAddValue(dict, CFSTR("WarmLEDPercentile"), threshold);
        // Now tell the camera the "fake" scene condition
        SetTorchColor(dict, stream, device);
        CFRelease(threshold);
        CFRelease(dict);
    }
    return result;
}

// Extra stuff
int (*SetTorchColorMode)(void *, unsigned int, unsigned short, unsigned short);
%hookf(int, SetTorchColorMode, void *arg0, unsigned int arg1, unsigned short mode, unsigned short warmLEDPercentile) {
    // As far as I can tell, mode = 1 probably forces both LEDs to be turned on.
    return %orig(arg0, arg1, mode, warmLEDPercentile);
}

%ctor {
    dlopen("/System/Library/MediaCapture/H10ISP.mediacapture", RTLD_LAZY);
    dlopen("/System/Library/MediaCapture/H9ISP.mediacapture", RTLD_LAZY);
    dlopen("/System/Library/MediaCapture/H6ISP.mediacapture", RTLD_LAZY);
    MSImageRef hxRef = MSGetImageByName("/System/Library/MediaCapture/H10ISP.mediacapture");
    if (hxRef == NULL)
        hxRef = MSGetImageByName("/System/Library/MediaCapture/H9ISP.mediacapture");
    if (hxRef == NULL)
        hxRef = MSGetImageByName("/System/Library/MediaCapture/H6ISP.mediacapture");
    SetTorchColor = (int (*)(CFMutableDictionaryRef, HXISPCaptureStreamRef, HXISPCaptureDeviceRef))MSFindSymbol(hxRef, "__ZL13SetTorchColorPKvP19H10ISPCaptureStreamP19H10ISPCaptureDevice");
    if (SetTorchColor == NULL)
        SetTorchColor = (int (*)(CFMutableDictionaryRef, HXISPCaptureStreamRef, HXISPCaptureDeviceRef))MSFindSymbol(hxRef, "__ZL13SetTorchColorPKvP18H9ISPCaptureStreamP18H9ISPCaptureDevice");
    if (SetTorchColor == NULL)
        SetTorchColor = (int (*)(CFMutableDictionaryRef, HXISPCaptureStreamRef, HXISPCaptureDeviceRef))MSFindSymbol(hxRef, "__ZL13SetTorchColorPKvP18H6ISPCaptureStreamP18H6ISPCaptureDevice");
    HBLogDebug(@"SetTorchColor found: %d", SetTorchColor != NULL);
    SetTorchColorMode = (int (*)(void *, unsigned int, unsigned short, unsigned short))MSFindSymbol(hxRef, "__ZN6H10ISP12H10ISPDevice17SetTorchColorModeEjtt");
    if (SetTorchColorMode == NULL)
        SetTorchColorMode = (int (*)(void *, unsigned int, unsigned short, unsigned short))MSFindSymbol(hxRef, "__ZN5H9ISP11H9ISPDevice17SetTorchColorModeEjtt");
    if (SetTorchColorMode == NULL)
        SetTorchColorMode = (int (*)(void *, unsigned int, unsigned short, unsigned short))MSFindSymbol(hxRef, "__ZN5H6ISP11H6ISPDevice17SetTorchColorModeEjtt");
    HBLogDebug(@"SetTorchColorMode found: %d", SetTorchColorMode != NULL);
    SetTorchLevel = (int (*)(CFNumberRef, HXISPCaptureStreamRef, HXISPCaptureDeviceRef))MSFindSymbol(hxRef, "__ZL13SetTorchLevelPKvP18H10ISPCaptureStreamP18H10ISPCaptureDevice");
    if (SetTorchLevel == NULL)
        SetTorchLevel = (int (*)(CFNumberRef, HXISPCaptureStreamRef, HXISPCaptureDeviceRef))MSFindSymbol(hxRef, "__ZL13SetTorchLevelPKvP18H9ISPCaptureStreamP18H9ISPCaptureDevice");
    if (SetTorchLevel == NULL)
        SetTorchLevel = (int (*)(CFNumberRef, HXISPCaptureStreamRef, HXISPCaptureDeviceRef))MSFindSymbol(hxRef, "__ZL13SetTorchLevelPKvP18H6ISPCaptureStreamP18H6ISPCaptureDevice");
    HBLogDebug(@"SetTorchLevel found: %d", SetTorchLevel != NULL);
    GetCFPreferenceNumber = (SInt32 (*)(CFStringRef const, CFStringRef const, SInt32))MSFindSymbol(hxRef, "__ZN6H10ISP27H10ISPGetCFPreferenceNumberEPK10__CFStringS2_i");
    if (GetCFPreferenceNumber == NULL)
        GetCFPreferenceNumber = (SInt32 (*)(CFStringRef const, CFStringRef const, SInt32))MSFindSymbol(hxRef, "__ZN5H9ISP26H9ISPGetCFPreferenceNumberEPK10__CFStringS2_i");
    if (GetCFPreferenceNumber == NULL)
        GetCFPreferenceNumber = (SInt32 (*)(CFStringRef const, CFStringRef const, SInt32))MSFindSymbol(hxRef, "__ZN5H6ISP26H6ISPGetCFPreferenceNumberEPK10__CFStringS2_i");
    HBLogDebug(@"GetCFPreferenceNumber found: %d", GetCFPreferenceNumber != NULL);
    %init;
}
