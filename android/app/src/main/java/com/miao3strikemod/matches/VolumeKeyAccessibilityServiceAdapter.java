package com.miao3strikemod.matches;

import android.content.Context;
import android.content.Intent;

public class VolumeKeyAccessibilityServiceAdapter {
    
    public static void setMasterEnabled(boolean enabled) {
        VolumeKeyAccessibilityService.setMasterEnabled(enabled);
    }
    
    public static void setFunctionEnabled(boolean enabled) {
        VolumeKeyAccessibilityService.setFunctionEnabled(enabled);
    }
    
    public static boolean isFunctionEnabled() {
        return VolumeKeyAccessibilityService.isFunctionEnabled();
    }
    
    public static void startAccessibilitySettings(Context context) {
        Intent intent = new Intent(android.provider.Settings.ACTION_ACCESSIBILITY_SETTINGS);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        context.startActivity(intent);
    }
}