package com.miao3strikemod.matches;

import android.content.Context;
import android.content.SharedPreferences;

public final class MacroConfig {

    private MacroConfig() {
    }

    public static final String PREFS_NAME = "miao3trike_prefs";

    public static final String KEY_STARTUP_DELAY_MS = "macro_startup_delay_ms";
    public static final String KEY_STEP_DELAY_MS = "macro_step_delay_ms";
    public static final String KEY_DRAG_DURATION_MS = "macro_drag_duration_ms";
    public static final String KEY_HOLD_DELAY_MS = "macro_hold_delay_ms";
    public static final String KEY_CLICK_CAPTURE_ENABLED = "macro_click_capture_enabled";
    public static final String KEY_STEP_MACRO_DELAY_MS = "macro_step_macro_delay_ms";
    public static final String KEY_STEP_MACRO_ENABLED = "macro_step_enabled";

    public static final long DEFAULT_STARTUP_DELAY_MS = 30L;
    public static final long DEFAULT_STEP_DELAY_MS = 0L;
    public static final long DEFAULT_DRAG_DURATION_MS = 50L;
    public static final long DEFAULT_HOLD_DELAY_MS = 200L;
    public static final boolean DEFAULT_CLICK_CAPTURE_ENABLED = true;
    public static final long DEFAULT_STEP_MACRO_DELAY_MS = 50L;
    public static final boolean DEFAULT_STEP_MACRO_ENABLED = true;

    public static final long MIN_STARTUP_DELAY_MS = 0L;
    public static final long MAX_STARTUP_DELAY_MS = 5000L;

    public static final long MIN_STEP_DELAY_MS = 0L;
    public static final long MAX_STEP_DELAY_MS = 1000L;

    public static final long MIN_DRAG_DURATION_MS = 50L;
    public static final long MAX_DRAG_DURATION_MS = 5000L;

    public static final long MIN_HOLD_DELAY_MS = 0L;
    public static final long MAX_HOLD_DELAY_MS = 5000L;

    public static final long MIN_STEP_MACRO_DELAY_MS = 0L;
    public static final long MAX_STEP_MACRO_DELAY_MS = 5000L;

    public static SharedPreferences prefs(Context context) {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
    }

    public static MacroDelays load(Context context) {
        SharedPreferences sp = prefs(context);
        long startup = clamp(sp.getLong(KEY_STARTUP_DELAY_MS, DEFAULT_STARTUP_DELAY_MS), MIN_STARTUP_DELAY_MS, MAX_STARTUP_DELAY_MS);
        long step = clamp(sp.getLong(KEY_STEP_DELAY_MS, DEFAULT_STEP_DELAY_MS), MIN_STEP_DELAY_MS, MAX_STEP_DELAY_MS);
        long drag = clamp(sp.getLong(KEY_DRAG_DURATION_MS, DEFAULT_DRAG_DURATION_MS), MIN_DRAG_DURATION_MS, MAX_DRAG_DURATION_MS);
        long hold = clamp(sp.getLong(KEY_HOLD_DELAY_MS, DEFAULT_HOLD_DELAY_MS), MIN_HOLD_DELAY_MS, MAX_HOLD_DELAY_MS);
        return new MacroDelays(startup, step, drag, hold);
    }

    public static void save(Context context, MacroDelays delays) {
        if (context == null || delays == null) return;
        prefs(context).edit()
                .putLong(KEY_STARTUP_DELAY_MS, clamp(delays.startupDelayMs, MIN_STARTUP_DELAY_MS, MAX_STARTUP_DELAY_MS))
                .putLong(KEY_STEP_DELAY_MS, clamp(delays.stepDelayMs, MIN_STEP_DELAY_MS, MAX_STEP_DELAY_MS))
                .putLong(KEY_DRAG_DURATION_MS, clamp(delays.dragDurationMs, MIN_DRAG_DURATION_MS, MAX_DRAG_DURATION_MS))
                .putLong(KEY_HOLD_DELAY_MS, clamp(delays.holdDelayMs, MIN_HOLD_DELAY_MS, MAX_HOLD_DELAY_MS))
                .apply();
    }

    public static void resetToDefaults(Context context) {
        save(context, new MacroDelays(DEFAULT_STARTUP_DELAY_MS, DEFAULT_STEP_DELAY_MS, DEFAULT_DRAG_DURATION_MS, DEFAULT_HOLD_DELAY_MS));
        setClickCaptureEnabled(context, DEFAULT_CLICK_CAPTURE_ENABLED);
        setStepMacroDelayMs(context, DEFAULT_STEP_MACRO_DELAY_MS);
        setStepMacroEnabled(context, DEFAULT_STEP_MACRO_ENABLED);
    }

    public static boolean isClickCaptureEnabled(Context context) {
        if (context == null) return DEFAULT_CLICK_CAPTURE_ENABLED;
        return prefs(context).getBoolean(KEY_CLICK_CAPTURE_ENABLED, DEFAULT_CLICK_CAPTURE_ENABLED);
    }

    public static void setClickCaptureEnabled(Context context, boolean enabled) {
        if (context == null) return;
        prefs(context).edit()
                .putBoolean(KEY_CLICK_CAPTURE_ENABLED, enabled)
                .apply();
    }

    public static long getStepMacroDelayMs(Context context) {
        if (context == null) return DEFAULT_STEP_MACRO_DELAY_MS;
        return clamp(
                prefs(context).getLong(KEY_STEP_MACRO_DELAY_MS, DEFAULT_STEP_MACRO_DELAY_MS),
                MIN_STEP_MACRO_DELAY_MS,
                MAX_STEP_MACRO_DELAY_MS
        );
    }

    public static void setStepMacroDelayMs(Context context, long delayMs) {
        if (context == null) return;
        prefs(context).edit()
                .putLong(KEY_STEP_MACRO_DELAY_MS, clamp(delayMs, MIN_STEP_MACRO_DELAY_MS, MAX_STEP_MACRO_DELAY_MS))
                .apply();
    }

    public static boolean isStepMacroEnabled(Context context) {
        if (context == null) return DEFAULT_STEP_MACRO_ENABLED;
        return prefs(context).getBoolean(KEY_STEP_MACRO_ENABLED, DEFAULT_STEP_MACRO_ENABLED);
    }

    public static void setStepMacroEnabled(Context context, boolean enabled) {
        if (context == null) return;
        prefs(context).edit()
                .putBoolean(KEY_STEP_MACRO_ENABLED, enabled)
                .apply();
    }

    public static long clamp(long value, long min, long max) {
        return Math.max(min, Math.min(max, value));
    }

    public static final class MacroDelays {
        public final long startupDelayMs;
        public final long stepDelayMs;
        public final long dragDurationMs;
        public final long holdDelayMs;

        public MacroDelays(long startupDelayMs, long stepDelayMs, long dragDurationMs, long holdDelayMs) {
            this.startupDelayMs = startupDelayMs;
            this.stepDelayMs = stepDelayMs;
            this.dragDurationMs = dragDurationMs;
            this.holdDelayMs = holdDelayMs;
        }
    }
}
