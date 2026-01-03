package com.miao3strikemod.matches;

import android.accessibilityservice.AccessibilityService;
import android.accessibilityservice.GestureDescription;
import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.PointF;
import android.graphics.PixelFormat;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowManager;
import android.view.accessibility.AccessibilityEvent;

/**
 * 无障碍服务：负责一次性录制拖动并执行宏（点击按钮中心 -> 拖动 -> 返回）。
 */
public class VolumeKeyAccessibilityService extends AccessibilityService {

    private static final String TAG = "VolumeKeyService";
    private static VolumeKeyAccessibilityService instance;
    private static boolean functionEnabled = false;
    private static boolean masterEnabled = false;

    private static final String PREF_KEY_BUTTON_CENTER_CUSTOMIZED = "button_center_customized";
    private static final String PREF_KEY_BUTTON_CENTER_X = "button_center_x";
    private static final String PREF_KEY_BUTTON_CENTER_Y = "button_center_y";

    // 坐标比例（基于 1920x1080 给定点计算得到）
    private static final float BUTTON_CENTER_RX = 0.9370f;
    private static final float BUTTON_CENTER_RY = 0.0745f;

    private static final long GESTURE_DELAY_MS = 10L;
    // 拖动时长（可配置）用于宏注入；为避免被系统忽略，建议不要过小。
    private static final long DRAG_TIMEOUT_MS = 3000L;
    private static final float MIN_DRAG_DISTANCE_PX = 5f;

    private static final long TAP_DURATION_MS = 10L;
    private static final long MACRO_TIMEOUT_MS = 5000L;

    private static final float BUTTON_MARKER_RADIUS_DP = 10f;
    private static final float BUTTON_MARKER_TOUCH_RADIUS_DP = 26f;

    private static final int RECORDING_MODE_NONE = 0;
    private static final int RECORDING_MODE_DRAG = 1;
    private static final int RECORDING_MODE_CLICK = 2;

    private final Handler handler = new Handler(Looper.getMainLooper());

    private WindowManager overlayWindowManager;
    private RecordingOverlayView overlayView;
    private WindowManager.LayoutParams overlayParams;

    private MacroState macroState;
    private ClickMacroState clickMacroState;
    private StepMacroState stepMacroState;

    private float buttonCenterX;
    private float buttonCenterY;
    private boolean draggingButtonCenter = false;
    private float buttonCenterDragOffsetX;
    private float buttonCenterDragOffsetY;

    private boolean recordingActive = false;
    private float startX;
    private float startY;
    private float currentX;
    private float currentY;
    private boolean showArrow = false;
    private long dragStartTime;

    private int recordingMode = RECORDING_MODE_NONE;
    private boolean clickCaptureActive = false;
    private boolean clickMacroRunning = false;
    private boolean resumeDragAfterClickCapture = false;
    private boolean stepMacroRunning = false;

    @Override
    public void onCreate() {
        super.onCreate();
        instance = this;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        removeOverlay();
        instance = null;
    }

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        // 未使用
    }

    @Override
    public void onInterrupt() {
        // 未使用
    }

    @Override
    protected boolean onKeyEvent(KeyEvent event) {
        if (event == null) return false;
        if (!masterEnabled) {
            return false;
        }
        if (event.getKeyCode() == KeyEvent.KEYCODE_VOLUME_UP
                && event.getAction() == KeyEvent.ACTION_DOWN) {
            if (macroState != null) {
                Log.d(TAG, "Ignore volume+ while drag macro running");
                return true;
            }
            if (isClickCaptureInProgressInternal()) {
                cancelClickCaptureInternal("volume_key_cancel");
                return true;
            }
            if (!MacroConfig.isClickCaptureEnabled(this)) {
                return false;
            }
            startClickCaptureOverlay();
            return true;
        }
        if (event.getKeyCode() == KeyEvent.KEYCODE_VOLUME_DOWN
                && event.getAction() == KeyEvent.ACTION_DOWN) {
            if (macroState != null) {
                Log.d(TAG, "Ignore volume- while drag macro running");
                return true;
            }
            if (isClickCaptureInProgressInternal()) {
                cancelClickCaptureInternal("volume_down_cancel");
                return true;
            }
            if (stepMacroRunning) {
                cancelStepMacroIfRunning("volume_down_cancel");
                return true;
            }
            if (!MacroConfig.isStepMacroEnabled(this)) {
                return false;
            }
            runStepMacroSequence(computeButtonCenter());
            return true;
        }
        return super.onKeyEvent(event);
    }

    /**
    * 开关由浮窗控制；开启时进入录制待机，关闭时清理。
    */
    public static void setFunctionEnabled(boolean enabled) {
        if (enabled && !masterEnabled) {
            Log.d(TAG, "Ignore function enable while master disabled");
            FloatingWindowService.notifyFunctionState(false);
            return;
        }
        functionEnabled = enabled;
        VolumeKeyAccessibilityService svc = instance;
        if (svc != null) {
            svc.onFunctionStateChanged(enabled);
        }
        FloatingWindowService.notifyFunctionState(enabled);
    }

    public static boolean isFunctionEnabled() {
        return functionEnabled;
    }

    public static void setMasterEnabled(boolean enabled) {
        masterEnabled = enabled;
        VolumeKeyAccessibilityService svc = instance;
        if (!enabled && svc != null) {
            svc.abortStepMacro("master_disabled");
            setFunctionEnabled(false);
        }
    }

    public static boolean isMasterEnabled() {
        return masterEnabled;
    }

    public static VolumeKeyAccessibilityService getInstance() {
        return instance;
    }

    public static boolean isClickCaptureInProgress() {
        VolumeKeyAccessibilityService svc = instance;
        return svc != null && svc.isClickCaptureInProgressInternal();
    }

    public static void cancelClickCapture(String reason) {
        VolumeKeyAccessibilityService svc = instance;
        if (svc != null) {
            svc.cancelClickCaptureInternal(reason);
        }
    }

    private void onFunctionStateChanged(boolean enabled) {
        if (enabled) {
            startRecordingOverlay();
        } else {
            if (isClickCaptureInProgressInternal()) {
                cancelClickCaptureInternal("function_disabled");
            }
            cancelMacroIfRunning("disabled");
            removeOverlay();
            recordingActive = false;
        }
    }

    /**
     * 添加全屏透明 overlay 捕获下一次拖动。
     */
    private void startRecordingOverlay() {
        if (overlayView != null || !functionEnabled) return;

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            Log.e(TAG, "Gesture dispatch requires API 24+, current=" + Build.VERSION.SDK_INT);
            failThisRound("api_too_low");
            return;
        }

        overlayWindowManager = (WindowManager) getSystemService(WINDOW_SERVICE);
        if (overlayWindowManager == null) {
            Log.e(TAG, "WindowManager null, cannot start overlay");
            return;
        }

        PointF initialButtonCenter = computeButtonCenter();
        buttonCenterX = initialButtonCenter.x;
        buttonCenterY = initialButtonCenter.y;

        overlayView = new RecordingOverlayView(this);
        overlayView.setOnTouchListener(this::handleOverlayTouch);

        int type;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            type = WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY;
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            type = WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY;
        } else {
            type = WindowManager.LayoutParams.TYPE_PHONE;
        }

        overlayParams = new WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                type,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                        | WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
                        | WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                PixelFormat.TRANSLUCENT
        );
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            overlayParams.layoutInDisplayCutoutMode =
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
        }

        try {
            overlayWindowManager.addView(overlayView, overlayParams);
            Log.d(TAG, "Recording overlay added");
            recordingMode = RECORDING_MODE_DRAG;
        } catch (Exception e) {
            Log.e(TAG, "Failed to add overlay", e);
            overlayView = null;
        }
    }

    private void removeOverlay() {
        if (overlayWindowManager != null && overlayView != null) {
            try {
                overlayWindowManager.removeView(overlayView);
                Log.d(TAG, "Recording overlay removed");
            } catch (Exception e) {
                Log.e(TAG, "Failed to remove overlay", e);
            }
        }
        overlayView = null;
        overlayParams = null;
        recordingMode = RECORDING_MODE_NONE;
    }

    private void startClickCaptureOverlay() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            Log.e(TAG, "Click capture requires API 24+, current=" + Build.VERSION.SDK_INT);
            return;
        }
        if (isClickCaptureInProgressInternal()) return;

        resumeDragAfterClickCapture = functionEnabled;
        clickCaptureActive = true;
        clickMacroRunning = false;
        recordingActive = false;
        showArrow = false;

        if (overlayView != null) {
            recordingMode = RECORDING_MODE_CLICK;
            if (overlayView != null) overlayView.invalidate();
            FloatingWindowService.notifyCaptureState(true);
            Log.d(TAG, "Click capture overlay reused");
            return;
        }

        overlayWindowManager = (WindowManager) getSystemService(WINDOW_SERVICE);
        if (overlayWindowManager == null) {
            Log.e(TAG, "WindowManager null, cannot start click capture overlay");
            clickCaptureActive = false;
            return;
        }

        PointF initialButtonCenter = computeButtonCenter();
        buttonCenterX = initialButtonCenter.x;
        buttonCenterY = initialButtonCenter.y;

        overlayView = new RecordingOverlayView(this);
        overlayView.setOnTouchListener(this::handleOverlayTouch);

        int type;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            type = WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY;
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            type = WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY;
        } else {
            type = WindowManager.LayoutParams.TYPE_PHONE;
        }

        overlayParams = new WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                type,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                        | WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
                        | WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                PixelFormat.TRANSLUCENT
        );
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            overlayParams.layoutInDisplayCutoutMode =
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
        }

        try {
            overlayWindowManager.addView(overlayView, overlayParams);
            recordingMode = RECORDING_MODE_CLICK;
            FloatingWindowService.notifyCaptureState(true);
            Log.d(TAG, "Click capture overlay added");
        } catch (Exception e) {
            Log.e(TAG, "Failed to add click capture overlay", e);
            overlayView = null;
            overlayParams = null;
            clickCaptureActive = false;
        }
    }

    private boolean handleOverlayTouch(View v, MotionEvent event) {
        if (recordingMode == RECORDING_MODE_CLICK) {
            return handleClickCaptureTouch(event);
        }
        if (!functionEnabled) return false;

        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
                if (event.getPointerCount() != 1) return false;
                float downX = event.getRawX();
                float downY = event.getRawY();
                if (isTouchNearButtonCenter(downX, downY)) {
                    draggingButtonCenter = true;
                    recordingActive = false;
                    showArrow = false;
                    buttonCenterDragOffsetX = buttonCenterX - downX;
                    buttonCenterDragOffsetY = buttonCenterY - downY;
                    if (overlayView != null) overlayView.invalidate();
                    Log.d(TAG, "Button center drag start x=" + buttonCenterX + ", y=" + buttonCenterY);
                    return true;
                }
                recordingActive = true;
                startX = downX;
                startY = downY;
                currentX = startX;
                currentY = startY;
                showArrow = true;
                dragStartTime = System.currentTimeMillis();
                if (overlayView != null) overlayView.invalidate();
                Log.d(TAG, "Drag start x=" + startX + ", y=" + startY);
                return true;
            case MotionEvent.ACTION_MOVE:
                if (draggingButtonCenter) {
                    float moveX = event.getRawX() + buttonCenterDragOffsetX;
                    float moveY = event.getRawY() + buttonCenterDragOffsetY;
                    setButtonCenter(moveX, moveY, false);
                    return true;
                }
                if (recordingActive) {
                    currentX = event.getRawX();
                    currentY = event.getRawY();
                    if (overlayView != null) overlayView.invalidate();
                }
                return recordingActive;
            case MotionEvent.ACTION_UP:
                if (draggingButtonCenter) {
                    draggingButtonCenter = false;
                    float upX = event.getRawX() + buttonCenterDragOffsetX;
                    float upY = event.getRawY() + buttonCenterDragOffsetY;
                    setButtonCenter(upX, upY, true);
                    Log.d(TAG, "Button center saved x=" + buttonCenterX + ", y=" + buttonCenterY);
                    return true;
                }
                if (!recordingActive) return false;
                if (event.getPointerCount() != 1) {
                    failThisRound("multi_pointer");
                    return true;
                }
                long duration = System.currentTimeMillis() - dragStartTime;
                float endX = event.getRawX();
                float endY = event.getRawY();
                float dx = Math.abs(endX - startX);
                float dy = Math.abs(endY - startY);
                float dist = (float) Math.hypot(dx, dy);
                currentX = endX;
                currentY = endY;
                if (overlayView != null) overlayView.invalidate();

                if (duration > DRAG_TIMEOUT_MS) {
                    failThisRound("timeout");
                } else if (dist < MIN_DRAG_DISTANCE_PX) {
                    failThisRound("too_short");
                } else {
                    Log.d(TAG, "Drag end x=" + endX + ", y=" + endY + ", dur=" + duration + "ms");
                    completeRecording(endX, endY);
                }
                return true;
            case MotionEvent.ACTION_CANCEL:
                if (draggingButtonCenter) {
                    draggingButtonCenter = false;
                    if (overlayView != null) overlayView.invalidate();
                    return true;
                }
                failThisRound("cancel");
                return true;
            default:
                return false;
        }
    }

    private boolean handleClickCaptureTouch(MotionEvent event) {
        if (!clickCaptureActive) return false;

        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
                if (event.getPointerCount() != 1) return false;
                return true;
            case MotionEvent.ACTION_MOVE:
                return true;
            case MotionEvent.ACTION_UP:
                if (event.getPointerCount() != 1) {
                    cancelClickCaptureInternal("click_multi_pointer");
                    return true;
                }
                PointF clickPoint = new PointF(event.getRawX(), event.getRawY());
                completeClickCapture(clickPoint);
                return true;
            case MotionEvent.ACTION_CANCEL:
                cancelClickCaptureInternal("click_cancel");
                return true;
            default:
                return false;
        }
    }

    private void completeClickCapture(PointF clickPoint) {
        clickCaptureActive = false;
        clickMacroRunning = true;
        showArrow = false;
        if (overlayView != null) overlayView.invalidate();

        deactivateOverlayForMacro();
        PointF buttonCenter = computeButtonCenter();
        runClickMacroSequence(buttonCenter, clickPoint);
    }

    private void failThisRound(String reason) {
        Log.w(TAG, "Recording failed: " + reason);
        recordingActive = false;
        removeOverlay();
        showArrow = false;
        if (overlayView != null) overlayView.invalidate();
        // 本轮结束，等待用户重新开启
        setFunctionEnabled(false);
    }

    private void completeRecording(float endX, float endY) {
        recordingActive = false;
        showArrow = false;
        if (overlayView != null) overlayView.invalidate();

        PointF start = new PointF(startX, startY);
        PointF end = new PointF(endX, endY);
        PointF buttonCenter = computeButtonCenter();

        deactivateOverlayForMacro();
        runMacroSequence(buttonCenter, start, end);
    }

    @SuppressLint("Deprecated")
    private DisplayMetrics getOverlayDisplayMetrics() {
        DisplayMetrics metrics = new DisplayMetrics();
        WindowManager wm = overlayWindowManager;
        if (wm == null) {
            wm = (WindowManager) getSystemService(WINDOW_SERVICE);
        }
        if (wm != null && wm.getDefaultDisplay() != null) {
            wm.getDefaultDisplay().getRealMetrics(metrics);
            if (metrics.widthPixels > 0 && metrics.heightPixels > 0) {
                return metrics;
            }
        }
        return getResources().getDisplayMetrics();
    }

    private PointF computeButtonCenter() {
        DisplayMetrics metrics = getOverlayDisplayMetrics();
        PointF customized = readCustomizedButtonCenter(metrics);
        if (customized != null) {
            return customized;
        }
        float x = BUTTON_CENTER_RX * metrics.widthPixels;
        float y = BUTTON_CENTER_RY * metrics.heightPixels;
        return new PointF(x, y);
    }

    private PointF readCustomizedButtonCenter(DisplayMetrics metrics) {
        try {
            boolean customized = getSharedPreferences(MacroConfig.PREFS_NAME, MODE_PRIVATE)
                    .getBoolean(PREF_KEY_BUTTON_CENTER_CUSTOMIZED, false);
            if (!customized) return null;
            float x = getSharedPreferences(MacroConfig.PREFS_NAME, MODE_PRIVATE)
                    .getFloat(PREF_KEY_BUTTON_CENTER_X, -1f);
            float y = getSharedPreferences(MacroConfig.PREFS_NAME, MODE_PRIVATE)
                    .getFloat(PREF_KEY_BUTTON_CENTER_Y, -1f);
            if (x < 0f || y < 0f) return null;
            float maxX = Math.max(0f, metrics.widthPixels - 1f);
            float maxY = Math.max(0f, metrics.heightPixels - 1f);
            float clampedX = clamp(x, 0f, maxX);
            float clampedY = clamp(y, 0f, maxY);
            return new PointF(clampedX, clampedY);
        } catch (Exception e) {
            Log.w(TAG, "readCustomizedButtonCenter failed", e);
            return null;
        }
    }

    private void persistButtonCenter(float x, float y) {
        try {
            getSharedPreferences(MacroConfig.PREFS_NAME, MODE_PRIVATE)
                    .edit()
                    .putBoolean(PREF_KEY_BUTTON_CENTER_CUSTOMIZED, true)
                    .putFloat(PREF_KEY_BUTTON_CENTER_X, x)
                    .putFloat(PREF_KEY_BUTTON_CENTER_Y, y)
                    .apply();
        } catch (Exception e) {
            Log.w(TAG, "persistButtonCenter failed", e);
        }
    }

    private void setButtonCenter(float x, float y, boolean persist) {
        DisplayMetrics metrics = getOverlayDisplayMetrics();
        float maxX = Math.max(0f, metrics.widthPixels - 1f);
        float maxY = Math.max(0f, metrics.heightPixels - 1f);
        buttonCenterX = clamp(x, 0f, maxX);
        buttonCenterY = clamp(y, 0f, maxY);
        if (overlayView != null) overlayView.invalidate();
        if (persist) {
            persistButtonCenter(buttonCenterX, buttonCenterY);
        }
    }

    private void deactivateOverlayForMacro() {
        if (overlayWindowManager == null || overlayView == null || overlayParams == null) return;
        try {
            overlayView.setAlpha(0f);
            overlayView.setVisibility(View.INVISIBLE);
        } catch (Exception e) {
            Log.w(TAG, "deactivateOverlayForMacro: view hide failed", e);
        }
        try {
            overlayParams.flags |= WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE;
            overlayWindowManager.updateViewLayout(overlayView, overlayParams);
            Log.d(TAG, "Overlay deactivated for macro (invisible + not touchable)");
        } catch (Exception e) {
            Log.w(TAG, "deactivateOverlayForMacro: updateViewLayout failed", e);
        }
    }

    private boolean isTouchNearButtonCenter(float rawX, float rawY) {
        float dx = rawX - buttonCenterX;
        float dy = rawY - buttonCenterY;
        float r = dpToPx(BUTTON_MARKER_TOUCH_RADIUS_DP);
        return (dx * dx + dy * dy) <= (r * r);
    }

    private float dpToPx(float dp) {
        return dp * getResources().getDisplayMetrics().density;
    }

    private static float clamp(float value, float min, float max) {
        return Math.max(min, Math.min(max, value));
    }

    private void runMacroSequence(PointF buttonCenter, PointF dragStart, PointF dragEnd) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            Log.e(TAG, "Gesture API requires 24+, current=" + Build.VERSION.SDK_INT);
            failThisRound("api_too_low");
            return;
        }
        cancelMacroIfRunning("restart");
        MacroConfig.MacroDelays delays = MacroConfig.load(this);
        MacroState state = new MacroState(buttonCenter, dragStart, dragEnd, delays);
        macroState = state;
        state.timeoutRunnable = () -> abortMacro("timeout");
        handler.postDelayed(state.timeoutRunnable, MACRO_TIMEOUT_MS);

        Log.d(TAG, "Run macro v2: startDelay=" + state.startupDelayMs + "ms, stepDelay=" + state.stepDelayMs
                + "ms, dragDuration=" + state.dragDurationMs + "ms, hold=" + state.holdDelayMs + "ms, tap=" + buttonCenter
                + " -> dragHold " + dragStart + " -> " + dragEnd
                + " -> back -> hold -> up");

        state.startRunnable = () -> {
            if (macroState != state) return;
            state.afterTapFallback = () -> macroStartDragHoldOnce(state, "tap_fallback");
            dispatchTap(buttonCenter, new GestureCallbackAdapter(
                    () -> macroStartDragHoldOnce(state, "tap_completed"),
                    () -> {
                        if (macroState == state) abortMacro("tap_cancelled");
                    }
            ));
            handler.postDelayed(state.afterTapFallback, TAP_DURATION_MS + 200);
        };
        handler.postDelayed(state.startRunnable, state.startupDelayMs);
    }

    private void runClickMacroSequence(PointF buttonCenter, PointF clickPoint) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            Log.e(TAG, "Click macro requires API 24+, current=" + Build.VERSION.SDK_INT);
            abortClickMacro("api_too_low_click");
            return;
        }
        cancelClickMacroIfRunning("restart");
        MacroConfig.MacroDelays delays = MacroConfig.load(this);
        ClickMacroState state = new ClickMacroState(buttonCenter, clickPoint, delays);
        clickMacroState = state;
        state.timeoutRunnable = () -> abortClickMacro("timeout");
        handler.postDelayed(state.timeoutRunnable, MACRO_TIMEOUT_MS);

        Log.d(TAG, "Run click macro: startDelay=" + state.startupDelayMs + "ms, stepDelay=" + state.stepDelayMs
                + "ms, tap=" + buttonCenter + " -> " + clickPoint + " -> " + buttonCenter);

        state.startRunnable = () -> {
            if (clickMacroState != state) return;
            state.afterTap1Fallback = () -> clickMacroTapTarget(state, "tap1_fallback");
            dispatchTap(buttonCenter, new GestureCallbackAdapter(
                    () -> clickMacroTapTarget(state, "tap1_completed"),
                    () -> abortClickMacro("tap1_cancelled")
            ));
            handler.postDelayed(state.afterTap1Fallback, TAP_DURATION_MS + 200);
        };
        handler.postDelayed(state.startRunnable, state.startupDelayMs);
    }

    private void clickMacroTapTarget(ClickMacroState state, String trigger) {
        if (clickMacroState != state || state.tap1Done) return;
        state.tap1Done = true;
        if (state.afterTap1Fallback != null) handler.removeCallbacks(state.afterTap1Fallback);

        handler.postDelayed(() -> {
            if (clickMacroState != state) return;
            state.afterTap2Fallback = () -> clickMacroTapButtonEnd(state, "tap2_fallback");
            dispatchTap(state.clickPoint, new GestureCallbackAdapter(
                    () -> clickMacroTapButtonEnd(state, "tap2_completed"),
                    () -> abortClickMacro("tap2_cancelled")
            ));
            handler.postDelayed(state.afterTap2Fallback, TAP_DURATION_MS + 200);
        }, state.stepDelayMs);
    }

    private void clickMacroTapButtonEnd(ClickMacroState state, String trigger) {
        if (clickMacroState != state || state.tap2Done) return;
        state.tap2Done = true;
        if (state.afterTap2Fallback != null) handler.removeCallbacks(state.afterTap2Fallback);

        handler.postDelayed(() -> {
            if (clickMacroState != state) return;
            state.afterTap3Fallback = this::finishClickMacro;
            dispatchTap(state.buttonCenter, new GestureCallbackAdapter(
                    this::finishClickMacro,
                    () -> abortClickMacro("tap3_cancelled")
            ));
            handler.postDelayed(state.afterTap3Fallback, TAP_DURATION_MS + 200);
        }, state.stepDelayMs);
    }

    private void runStepMacroSequence(PointF buttonCenter) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            Log.e(TAG, "Step macro requires API 24+, current=" + Build.VERSION.SDK_INT);
            abortStepMacro("api_too_low_step");
            return;
        }
        cancelStepMacroIfRunning("restart");
        long stepDelayMs = MacroConfig.getStepMacroDelayMs(this);
        StepMacroState state = new StepMacroState(buttonCenter, stepDelayMs);
        stepMacroState = state;
        stepMacroRunning = true;
        state.timeoutRunnable = () -> abortStepMacro("timeout");
        handler.postDelayed(state.timeoutRunnable, MACRO_TIMEOUT_MS);

        Log.d(TAG, "Run step macro: stepDelay=" + state.stepDelayMs + "ms, tap=" + buttonCenter + " -> tap");

        state.startRunnable = () -> {
            if (stepMacroState != state) return;
            state.afterTap1Fallback = () -> stepMacroTapEnd(state, "tap1_fallback");
            dispatchTap(buttonCenter, new GestureCallbackAdapter(
                    () -> stepMacroTapEnd(state, "tap1_completed"),
                    () -> abortStepMacro("tap1_cancelled")
            ));
            handler.postDelayed(state.afterTap1Fallback, TAP_DURATION_MS + 200);
        };
        handler.post(state.startRunnable);
    }

    private void stepMacroTapEnd(StepMacroState state, String trigger) {
        if (stepMacroState != state || state.tap1Done) return;
        state.tap1Done = true;
        if (state.afterTap1Fallback != null) handler.removeCallbacks(state.afterTap1Fallback);

        handler.postDelayed(() -> {
            if (stepMacroState != state) return;
            state.afterTap2Fallback = this::finishStepMacro;
            dispatchTap(state.buttonCenter, new GestureCallbackAdapter(
                    this::finishStepMacro,
                    () -> abortStepMacro("tap2_cancelled")
            ));
            handler.postDelayed(state.afterTap2Fallback, TAP_DURATION_MS + 200);
        }, state.stepDelayMs);
    }

    @TargetApi(Build.VERSION_CODES.N)
    private void dispatchTap(PointF point, GestureResultCallback result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            if (clickMacroRunning) {
                abortClickMacro("api_too_low_tap");
            } else if (stepMacroRunning) {
                abortStepMacro("api_too_low_tap");
            } else {
                failThisRound("api_too_low_tap");
            }
            return;
        }
        Path path = new Path();
        path.moveTo(point.x, point.y);
        GestureDescription.StrokeDescription stroke =
                new GestureDescription.StrokeDescription(path, 0, TAP_DURATION_MS);
        GestureDescription gesture = new GestureDescription.Builder()
                .addStroke(stroke)
                .build();

        boolean dispatched = dispatchGesture(gesture, result, null);
        Log.d(TAG, "dispatchTap dispatched=" + dispatched + " to " + point);
        if (!dispatched) {
            if (clickMacroRunning) {
                abortClickMacro("gesture_dispatch_failed_tap");
            } else if (stepMacroRunning) {
                abortStepMacro("gesture_dispatch_failed_tap");
            } else {
                failThisRound("gesture_dispatch_failed_tap");
            }
        }
    }

    @TargetApi(Build.VERSION_CODES.N)
    private void dispatchDrag(PointF start, PointF end, long durationMs, GestureResultCallback result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            failThisRound("api_too_low_drag");
            return;
        }
        Path path = new Path();
        path.moveTo(start.x, start.y);
        path.lineTo(end.x, end.y);

        long clampedDurationMs = MacroConfig.clamp(
                durationMs,
                MacroConfig.MIN_DRAG_DURATION_MS,
                MacroConfig.MAX_DRAG_DURATION_MS
        );
        GestureDescription.StrokeDescription stroke =
                new GestureDescription.StrokeDescription(path, 0, clampedDurationMs);
        GestureDescription gesture = new GestureDescription.Builder()
                .addStroke(stroke)
                .build();

        boolean dispatched = dispatchGesture(gesture, result, null);
        Log.d(TAG, "dispatchDrag dispatched=" + dispatched + " from " + start + " to " + end);
        if (!dispatched) {
            failThisRound("gesture_dispatch_failed_drag");
        }
    }

    private void finishRound() {
        cancelMacroIfRunning("finished");
        Log.d(TAG, "Macro finished");
        setFunctionEnabled(false);
    }

    private boolean isClickCaptureInProgressInternal() {
        return clickCaptureActive || clickMacroRunning;
    }

    private void cancelClickCaptureInternal(String reason) {
        if (!isClickCaptureInProgressInternal()) return;
        Log.d(TAG, "Click capture cancelled: " + reason);
        clickCaptureActive = false;
        clickMacroRunning = false;
        cancelClickMacroIfRunning(reason);
        FloatingWindowService.notifyCaptureState(false);
        removeOverlay();
        if (resumeDragAfterClickCapture && functionEnabled) {
            startRecordingOverlay();
        }
        resumeDragAfterClickCapture = false;
    }

    private void abortMacro(String reason) {
        Log.w(TAG, "Macro aborted: " + reason);
        cancelMacroIfRunning(reason);
        setFunctionEnabled(false);
    }

    private void cancelMacroIfRunning(String reason) {
        MacroState state = macroState;
        if (state == null) return;
        Log.d(TAG, "Cancel macro: " + reason);
        if (state.timeoutRunnable != null) handler.removeCallbacks(state.timeoutRunnable);
        if (state.startRunnable != null) handler.removeCallbacks(state.startRunnable);
        if (state.afterTapFallback != null) handler.removeCallbacks(state.afterTapFallback);
        if (state.afterDragFallback != null) handler.removeCallbacks(state.afterDragFallback);
        if (state.finishFallback != null) handler.removeCallbacks(state.finishFallback);
        macroState = null;
    }

    private void abortClickMacro(String reason) {
        Log.w(TAG, "Click macro aborted: " + reason);
        cancelClickMacroIfRunning(reason);
        clickMacroRunning = false;
        FloatingWindowService.notifyCaptureState(false);
        removeOverlay();
        if (resumeDragAfterClickCapture && functionEnabled) {
            startRecordingOverlay();
        }
        resumeDragAfterClickCapture = false;
    }

    private void abortStepMacro(String reason) {
        Log.w(TAG, "Step macro aborted: " + reason);
        cancelStepMacroIfRunning(reason);
        stepMacroRunning = false;
    }

    private void finishClickMacro() {
        cancelClickMacroIfRunning("finished");
        clickMacroRunning = false;
        FloatingWindowService.notifyCaptureState(false);
        removeOverlay();
        if (resumeDragAfterClickCapture && functionEnabled) {
            startRecordingOverlay();
        }
        resumeDragAfterClickCapture = false;
    }

    private void finishStepMacro() {
        cancelStepMacroIfRunning("finished");
        stepMacroRunning = false;
    }

    private void cancelClickMacroIfRunning(String reason) {
        ClickMacroState state = clickMacroState;
        if (state == null) return;
        Log.d(TAG, "Cancel click macro: " + reason);
        if (state.timeoutRunnable != null) handler.removeCallbacks(state.timeoutRunnable);
        if (state.startRunnable != null) handler.removeCallbacks(state.startRunnable);
        if (state.afterTap1Fallback != null) handler.removeCallbacks(state.afterTap1Fallback);
        if (state.afterTap2Fallback != null) handler.removeCallbacks(state.afterTap2Fallback);
        if (state.afterTap3Fallback != null) handler.removeCallbacks(state.afterTap3Fallback);
        clickMacroState = null;
    }

    private void cancelStepMacroIfRunning(String reason) {
        StepMacroState state = stepMacroState;
        if (state == null) return;
        Log.d(TAG, "Cancel step macro: " + reason);
        if (state.timeoutRunnable != null) handler.removeCallbacks(state.timeoutRunnable);
        if (state.startRunnable != null) handler.removeCallbacks(state.startRunnable);
        if (state.afterTap1Fallback != null) handler.removeCallbacks(state.afterTap1Fallback);
        if (state.afterTap2Fallback != null) handler.removeCallbacks(state.afterTap2Fallback);
        stepMacroState = null;
    }

    private void macroStartDragHoldOnce(MacroState state, String trigger) {
        if (macroState != state || state.dragStarted) return;
        state.dragStarted = true;
        if (state.afterTapFallback != null) handler.removeCallbacks(state.afterTapFallback);

        handler.postDelayed(() -> macroDispatchDragHold(state, trigger), state.stepDelayMs);
    }

    @TargetApi(Build.VERSION_CODES.N)
    private void macroDispatchDragHold(MacroState state, String trigger) {
        if (macroState != state) return;

        // API 24/25 上不保证支持“继续笔画”；此处提供降级：普通拖动（会松手）→ 返回 → 结束。
        GestureDescription.StrokeDescription dragHoldStroke = createDragStroke(state.dragStart, state.dragEnd, true, state.dragDurationMs);
        if (dragHoldStroke == null) {
            Log.w(TAG, "Continuous stroke unsupported, fallback to normal drag. trigger=" + trigger);
            dispatchDrag(state.dragStart, state.dragEnd, state.dragDurationMs, new GestureCallbackAdapter(
                    () -> handler.postDelayed(() -> {
                        if (macroState != state) return;
                        boolean backOk = performGlobalAction(GLOBAL_ACTION_BACK);
                        Log.d(TAG, "performGlobalAction(BACK) ok=" + backOk + " (fallback)");
                        finishRound();
                    }, state.stepDelayMs),
                    () -> {
                        if (macroState == state) abortMacro("drag_fallback_cancelled");
                    }
            ));
            state.finishFallback = () -> {
                if (macroState == state) finishRound();
            };
            handler.postDelayed(state.finishFallback, state.dragDurationMs + 500);
            return;
        }

        state.heldStroke = dragHoldStroke;
        GestureDescription gesture = new GestureDescription.Builder()
                .addStroke(dragHoldStroke)
                .build();

        state.afterDragFallback = () -> macroAfterDragHoldOnce(state, "drag_fallback");
        boolean dispatched = dispatchGesture(gesture, new GestureCallbackAdapter(
                () -> macroAfterDragHoldOnce(state, "drag_completed"),
                () -> {
                    if (macroState == state) abortMacro("drag_hold_cancelled");
                }
        ), null);
        Log.d(TAG, "dispatchDragHold dispatched=" + dispatched + " trigger=" + trigger);
        if (!dispatched) {
            abortMacro("gesture_dispatch_failed_drag_hold");
            return;
        }
        handler.postDelayed(state.afterDragFallback, state.dragDurationMs + 200);
    }

    private void macroAfterDragHoldOnce(MacroState state, String trigger) {
        if (macroState != state || state.afterDragInvoked) return;
        state.afterDragInvoked = true;
        if (state.afterDragFallback != null) handler.removeCallbacks(state.afterDragFallback);

        handler.postDelayed(() -> {
            if (macroState != state) return;
            boolean backOk = performGlobalAction(GLOBAL_ACTION_BACK);
            Log.d(TAG, "performGlobalAction(BACK) ok=" + backOk + " trigger=" + trigger);
            macroDispatchHoldAndRelease(state);
        }, state.stepDelayMs);
    }

    @TargetApi(Build.VERSION_CODES.N)
    private void macroDispatchHoldAndRelease(MacroState state) {
        if (macroState != state) return;
        if (state.heldStroke == null) {
            abortMacro("missing_held_stroke");
            return;
        }

        long holdDurationMs = Math.max(1L, state.holdDelayMs);
        GestureDescription.StrokeDescription endHoldAndUp = continueStrokeAtEnd(state.heldStroke, state.dragEnd, holdDurationMs);
        if (endHoldAndUp == null) {
            Log.w(TAG, "continueStroke unavailable; cannot guarantee hold+release. Ending macro.");
            finishRound();
            return;
        }

        GestureDescription gesture = new GestureDescription.Builder()
                .addStroke(endHoldAndUp)
                .build();

        state.finishFallback = () -> {
            if (macroState == state) finishRound();
        };
        boolean dispatched = dispatchGesture(gesture, new GestureCallbackAdapter(
                () -> {
                    if (macroState == state) finishRound();
                },
                () -> {
                    if (macroState == state) abortMacro("hold_release_cancelled");
                }
        ), null);
        Log.d(TAG, "dispatchHoldAndRelease dispatched=" + dispatched);
        if (!dispatched) {
            abortMacro("gesture_dispatch_failed_hold_release");
            return;
        }
        handler.postDelayed(state.finishFallback, holdDurationMs + 500);
    }

    private GestureDescription.StrokeDescription createDragStroke(PointF start, PointF end, boolean willContinue, long durationMs) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return null;
        Path path = new Path();
        path.moveTo(start.x, start.y);
        path.lineTo(end.x, end.y);

        long clampedDurationMs = MacroConfig.clamp(
                durationMs,
                MacroConfig.MIN_DRAG_DURATION_MS,
                MacroConfig.MAX_DRAG_DURATION_MS
        );
        if (willContinue) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return null;
            try {
                return new GestureDescription.StrokeDescription(path, 0, clampedDurationMs, true);
            } catch (NoSuchMethodError e) {
                Log.w(TAG, "StrokeDescription(willContinue) unsupported: " + e);
                return null;
            }
        }

        return new GestureDescription.StrokeDescription(path, 0, clampedDurationMs);
    }

    private GestureDescription.StrokeDescription continueStrokeAtEnd(
            GestureDescription.StrokeDescription previousStroke,
            PointF end,
            long holdDurationMs
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return null;
        try {
            Path path = new Path();
            path.moveTo(end.x, end.y);
            path.lineTo(end.x, end.y);
            return previousStroke.continueStroke(path, 0, holdDurationMs, false);
        } catch (NoSuchMethodError e) {
            Log.w(TAG, "continueStroke unsupported: " + e);
            return null;
        }
    }

    private static class GestureCallbackAdapter extends GestureResultCallback {
        private final Runnable onCompleted;
        private final Runnable onCancelled;

        GestureCallbackAdapter(Runnable onCompleted) {
            this(onCompleted, null);
        }

        GestureCallbackAdapter(Runnable onCompleted, Runnable onCancelled) {
            this.onCompleted = onCompleted;
            this.onCancelled = onCancelled;
        }

        @Override
        public void onCompleted(GestureDescription gestureDescription) {
            Log.d(TAG, "Gesture completed: " + gestureDescription);
            if (onCompleted != null) {
                onCompleted.run();
            }
        }

        @Override
        public void onCancelled(GestureDescription gestureDescription) {
            Log.w(TAG, "Gesture cancelled: " + gestureDescription);
            if (onCancelled != null) {
                onCancelled.run();
                return;
            }
            setFunctionEnabled(false);
        }
    }

    private static class ClickMacroState {
        final PointF buttonCenter;
        final PointF clickPoint;
        final long startupDelayMs;
        final long stepDelayMs;

        boolean tap1Done = false;
        boolean tap2Done = false;

        Runnable timeoutRunnable;
        Runnable startRunnable;
        Runnable afterTap1Fallback;
        Runnable afterTap2Fallback;
        Runnable afterTap3Fallback;

        ClickMacroState(PointF buttonCenter, PointF clickPoint, MacroConfig.MacroDelays delays) {
            this.buttonCenter = buttonCenter;
            this.clickPoint = clickPoint;
            this.startupDelayMs = delays.startupDelayMs;
            this.stepDelayMs = delays.stepDelayMs;
        }
    }

    private static class StepMacroState {
        final PointF buttonCenter;
        final long stepDelayMs;

        boolean tap1Done = false;

        Runnable timeoutRunnable;
        Runnable startRunnable;
        Runnable afterTap1Fallback;
        Runnable afterTap2Fallback;

        StepMacroState(PointF buttonCenter, long stepDelayMs) {
            this.buttonCenter = buttonCenter;
            this.stepDelayMs = stepDelayMs;
        }
    }

    private static class MacroState {
        final PointF buttonCenter;
        final PointF dragStart;
        final PointF dragEnd;
        final long startupDelayMs;
        final long stepDelayMs;
        final long dragDurationMs;
        final long holdDelayMs;

        boolean dragStarted = false;
        boolean afterDragInvoked = false;
        GestureDescription.StrokeDescription heldStroke;

        Runnable timeoutRunnable;
        Runnable startRunnable;
        Runnable afterTapFallback;
        Runnable afterDragFallback;
        Runnable finishFallback;

        MacroState(PointF buttonCenter, PointF dragStart, PointF dragEnd, MacroConfig.MacroDelays delays) {
            this.buttonCenter = buttonCenter;
            this.dragStart = dragStart;
            this.dragEnd = dragEnd;
            this.startupDelayMs = delays.startupDelayMs;
            this.stepDelayMs = delays.stepDelayMs;
            this.dragDurationMs = delays.dragDurationMs;
            this.holdDelayMs = delays.holdDelayMs;
        }
    }

    /**
     * 录制过程中绘制箭头指示拖动起止位置。
     */
    private class RecordingOverlayView extends View {
        private final Paint linePaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Paint circlePaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Paint markerFillPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Paint markerRingPaint = new Paint(Paint.ANTI_ALIAS_FLAG);

        RecordingOverlayView(android.content.Context context) {
            super(context);
            setWillNotDraw(false);
            linePaint.setColor(0x88FFC107);
            linePaint.setStrokeWidth(8f);
            linePaint.setStyle(Paint.Style.STROKE);

            circlePaint.setColor(0xAAFFC107);
            circlePaint.setStyle(Paint.Style.FILL);

            markerFillPaint.setColor(0xCC00BCD4);
            markerFillPaint.setStyle(Paint.Style.FILL);

            markerRingPaint.setColor(0xEE00BCD4);
            markerRingPaint.setStyle(Paint.Style.STROKE);
            markerRingPaint.setStrokeWidth(dpToPx(2.5f));
        }

        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            // 按钮中心指示点：可拖动，用于校准点击坐标（适配非 16:9）。
            float markerR = dpToPx(BUTTON_MARKER_RADIUS_DP);
            float ringR = markerR + dpToPx(draggingButtonCenter ? 10f : 6f);
            canvas.drawCircle(buttonCenterX, buttonCenterY, ringR, markerRingPaint);
            canvas.drawCircle(buttonCenterX, buttonCenterY, markerR, markerFillPaint);

            if (!recordingActive && !showArrow) return;
            float sx = startX;
            float sy = startY;
            float ex = currentX;
            float ey = currentY;

            // 绘制起点终点圆
            canvas.drawCircle(sx, sy, 12f, circlePaint);
            canvas.drawCircle(ex, ey, 12f, circlePaint);

            // 绘制箭头线
            canvas.drawLine(sx, sy, ex, ey, linePaint);

            // 绘制箭头尖
            float dx = ex - sx;
            float dy = ey - sy;
            float len = (float) Math.hypot(dx, dy);
            if (len > 0) {
                float ux = dx / len;
                float uy = dy / len;
                float arrowLen = 36f;
                float arrowWidth = 14f;
                float bx = ex - arrowLen * ux;
                float by = ey - arrowLen * uy;
                float perpX = -uy;
                float perpY = ux;
                float x1 = bx + arrowWidth * perpX;
                float y1 = by + arrowWidth * perpY;
                float x2 = bx - arrowWidth * perpX;
                float y2 = by - arrowWidth * perpY;

                Path arrow = new Path();
                arrow.moveTo(ex, ey);
                arrow.lineTo(x1, y1);
                arrow.lineTo(x2, y2);
                arrow.close();
                canvas.drawPath(arrow, circlePaint);
            }
        }

        @Override
        @SuppressLint("ClickableViewAccessibility")
        public boolean performClick() {
            // 触摸事件已在 onTouch 中处理，这里仅满足可访问性要求。
            return super.performClick();
        }
    }
}
