package com.ark3trike.matches;

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

    private static final String PREFS_NAME = "miao3trike_prefs";
    private static final String PREF_KEY_BUTTON_CENTER_CUSTOMIZED = "button_center_customized";
    private static final String PREF_KEY_BUTTON_CENTER_X = "button_center_x";
    private static final String PREF_KEY_BUTTON_CENTER_Y = "button_center_y";

    // 坐标比例（基于 1920x1080 给定点计算得到）
    private static final float BUTTON_CENTER_RX = 0.9370f;
    private static final float BUTTON_CENTER_RY = 0.0745f;

    private static final long GESTURE_DELAY_MS = 10L;
    private static final long DELAY_AFTER_OVERLAY_DEACTIVATION_MS = 30L; // 等待 overlay 更新为不可触摸/隐藏后再开始宏
    private static final long DRAG_DURATION_MS = 400L;      // 拖动时长，避免被系统忽略
    private static final long DRAG_TIMEOUT_MS = 3000L;
    private static final float MIN_DRAG_DISTANCE_PX = 5f;

    private static final long TAP_DURATION_MS = 10L;
    private static final long MACRO_STEP_DELAY_MS = 10L;
    private static final long MACRO_HOLD_AT_END_MS = 500L;
    private static final long MACRO_TIMEOUT_MS = 5000L;

    private static final float BUTTON_MARKER_RADIUS_DP = 10f;
    private static final float BUTTON_MARKER_TOUCH_RADIUS_DP = 26f;

    private final Handler handler = new Handler(Looper.getMainLooper());

    private WindowManager overlayWindowManager;
    private RecordingOverlayView overlayView;
    private WindowManager.LayoutParams overlayParams;

    private MacroState macroState;

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

    /**
    * 开关由浮窗控制；开启时进入录制待机，关闭时清理。
    */
    public static void setFunctionEnabled(boolean enabled) {
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

    public static VolumeKeyAccessibilityService getInstance() {
        return instance;
    }

    private void onFunctionStateChanged(boolean enabled) {
        if (enabled) {
            startRecordingOverlay();
        } else {
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
                        | WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT
        );
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            overlayParams.layoutInDisplayCutoutMode =
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
        }

        try {
            overlayWindowManager.addView(overlayView, overlayParams);
            Log.d(TAG, "Recording overlay added");
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
    }

    private boolean handleOverlayTouch(View v, MotionEvent event) {
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

    private PointF computeButtonCenter() {
        DisplayMetrics metrics = getResources().getDisplayMetrics();
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
            boolean customized = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
                    .getBoolean(PREF_KEY_BUTTON_CENTER_CUSTOMIZED, false);
            if (!customized) return null;
            float x = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
                    .getFloat(PREF_KEY_BUTTON_CENTER_X, -1f);
            float y = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
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
            getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
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
        DisplayMetrics metrics = getResources().getDisplayMetrics();
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
        MacroState state = new MacroState(buttonCenter, dragStart, dragEnd);
        macroState = state;
        state.timeoutRunnable = () -> abortMacro("timeout");
        handler.postDelayed(state.timeoutRunnable, MACRO_TIMEOUT_MS);

        Log.d(TAG, "Run macro v2: startDelay=" + DELAY_AFTER_OVERLAY_DEACTIVATION_MS + "ms, tap=" + buttonCenter
                + " -> dragHold " + dragStart + " -> " + dragEnd
                + " -> back -> hold " + MACRO_HOLD_AT_END_MS + "ms -> up");

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
        handler.postDelayed(state.startRunnable, DELAY_AFTER_OVERLAY_DEACTIVATION_MS);
    }

    @TargetApi(Build.VERSION_CODES.N)
    private void dispatchTap(PointF point, GestureResultCallback result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            failThisRound("api_too_low_tap");
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
            failThisRound("gesture_dispatch_failed_tap");
        }
    }

    @TargetApi(Build.VERSION_CODES.N)
    private void dispatchDrag(PointF start, PointF end, GestureResultCallback result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            failThisRound("api_too_low_drag");
            return;
        }
        Path path = new Path();
        path.moveTo(start.x, start.y);
        path.lineTo(end.x, end.y);

        GestureDescription.StrokeDescription stroke =
                new GestureDescription.StrokeDescription(path, 0, DRAG_DURATION_MS);
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

    private void macroStartDragHoldOnce(MacroState state, String trigger) {
        if (macroState != state || state.dragStarted) return;
        state.dragStarted = true;
        if (state.afterTapFallback != null) handler.removeCallbacks(state.afterTapFallback);

        handler.postDelayed(() -> macroDispatchDragHold(state, trigger), MACRO_STEP_DELAY_MS);
    }

    @TargetApi(Build.VERSION_CODES.N)
    private void macroDispatchDragHold(MacroState state, String trigger) {
        if (macroState != state) return;

        // API 24/25 上不保证支持“继续笔画”；此处提供降级：普通拖动（会松手）→ 返回 → 结束。
        GestureDescription.StrokeDescription dragHoldStroke = createDragStroke(state.dragStart, state.dragEnd, true);
        if (dragHoldStroke == null) {
            Log.w(TAG, "Continuous stroke unsupported, fallback to normal drag. trigger=" + trigger);
            dispatchDrag(state.dragStart, state.dragEnd, new GestureCallbackAdapter(
                    () -> handler.postDelayed(() -> {
                        if (macroState != state) return;
                        boolean backOk = performGlobalAction(GLOBAL_ACTION_BACK);
                        Log.d(TAG, "performGlobalAction(BACK) ok=" + backOk + " (fallback)");
                        finishRound();
                    }, MACRO_STEP_DELAY_MS),
                    () -> {
                        if (macroState == state) abortMacro("drag_fallback_cancelled");
                    }
            ));
            state.finishFallback = () -> {
                if (macroState == state) finishRound();
            };
            handler.postDelayed(state.finishFallback, DRAG_DURATION_MS + 500);
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
        handler.postDelayed(state.afterDragFallback, DRAG_DURATION_MS + 200);
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
        }, MACRO_STEP_DELAY_MS);
    }

    @TargetApi(Build.VERSION_CODES.N)
    private void macroDispatchHoldAndRelease(MacroState state) {
        if (macroState != state) return;
        if (state.heldStroke == null) {
            abortMacro("missing_held_stroke");
            return;
        }

        GestureDescription.StrokeDescription endHoldAndUp = continueStrokeAtEnd(state.heldStroke, state.dragEnd, MACRO_HOLD_AT_END_MS);
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
        handler.postDelayed(state.finishFallback, MACRO_HOLD_AT_END_MS + 500);
    }

    private GestureDescription.StrokeDescription createDragStroke(PointF start, PointF end, boolean willContinue) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return null;
        Path path = new Path();
        path.moveTo(start.x, start.y);
        path.lineTo(end.x, end.y);

        if (willContinue) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return null;
            try {
                return new GestureDescription.StrokeDescription(path, 0, DRAG_DURATION_MS, true);
            } catch (NoSuchMethodError e) {
                Log.w(TAG, "StrokeDescription(willContinue) unsupported: " + e);
                return null;
            }
        }

        return new GestureDescription.StrokeDescription(path, 0, DRAG_DURATION_MS);
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

    private static class MacroState {
        final PointF buttonCenter;
        final PointF dragStart;
        final PointF dragEnd;

        boolean dragStarted = false;
        boolean afterDragInvoked = false;
        GestureDescription.StrokeDescription heldStroke;

        Runnable timeoutRunnable;
        Runnable startRunnable;
        Runnable afterTapFallback;
        Runnable afterDragFallback;
        Runnable finishFallback;

        MacroState(PointF buttonCenter, PointF dragStart, PointF dragEnd) {
            this.buttonCenter = buttonCenter;
            this.dragStart = dragStart;
            this.dragEnd = dragEnd;
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
