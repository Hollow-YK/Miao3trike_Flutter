package com.miao3strikemod.matches;

import android.accessibilityservice.AccessibilityServiceInfo;
import android.app.ActivityManager;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.view.LayoutInflater;
import android.view.View;
import android.view.accessibility.AccessibilityManager;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.SwitchCompat;

import java.util.List;

public class MainActivity extends AppCompatActivity {

    private View accessibilityButton;
    private View overlayButton;
    private View settingsButton;
    private SwitchCompat toggleServiceSwitch;
    private TextView tvAuthor;
    private TextView tvModAuthor;
    private ImageView imgCharacter;

    private ImageView checkAccessibility;
    private ImageView checkOverlay;
    private ImageView checkService;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // 设置沉浸式状态栏颜色
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            getWindow().setStatusBarColor(Color.parseColor("#00BCD4"));
        }

        if (getSupportActionBar() != null) {
            getSupportActionBar().hide();
        }
        setContentView(R.layout.activity_main);

        initViews();
        setupClickListeners();
    }

    private void initViews() {
        accessibilityButton = findViewById(R.id.btn_accessibility_container);
        overlayButton = findViewById(R.id.btn_overlay_container);
        settingsButton = findViewById(R.id.btn_settings_container);
        toggleServiceSwitch = findViewById(R.id.btn_toggle_service);
        tvAuthor = findViewById(R.id.tv_author);
        tvModAuthor = findViewById(R.id.tv_modauthor);
        imgCharacter = findViewById(R.id.img_character);

        checkAccessibility = findViewById(R.id.icon_check_accessibility);
        checkOverlay = findViewById(R.id.icon_check_overlay);
        checkService = findViewById(R.id.icon_check_service);
    }

    private void setupClickListeners() {
        // 无障碍按钮
        accessibilityButton.setOnClickListener(v -> {
            try {
                Intent intent = new Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS);
                startActivity(intent);
                Toast.makeText(this, "请在列表中开启 Miao3trikeMod", Toast.LENGTH_LONG).show();
            } catch (Exception e) {
                Toast.makeText(this, "无法打开无障碍设置", Toast.LENGTH_SHORT).show();
            }
        });

        // 悬浮窗按钮
        overlayButton.setOnClickListener(v -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (!Settings.canDrawOverlays(this)) {
                    Intent intent = new Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:" + getPackageName())
                    );
                    startActivity(intent);
                } else {
                    Toast.makeText(this, "悬浮窗权限已授予", Toast.LENGTH_SHORT).show();
                }
            }
        });

        settingsButton.setOnClickListener(v -> showMacroSettingsDialog());

        // 开关逻辑
        toggleServiceSwitch.setOnClickListener(v -> {
            boolean newState = toggleServiceSwitch.isChecked();

            if (newState) {
                if (checkPermissionsAndStart()) {
                    toggleServiceSwitch.setChecked(true);
                } else {
                    toggleServiceSwitch.setChecked(false);
                }
            } else {
                stopServiceLogic();
                toggleServiceSwitch.setChecked(false);
                updateCheckIcons(); // 立即更新图标
            }
        });

        // 作者链接点击
        tvAuthor.setOnClickListener(v -> {
            try {
                Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse("https://space.bilibili.com/506666307"));
                startActivity(intent);
            } catch (Exception e) {
                Toast.makeText(this, "无法打开链接", Toast.LENGTH_SHORT).show();
            }
        });

        // 魔改者链接点击
        tvModAuthor.setOnClickListener(v -> {
            try {
                Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse("https://space.bilibili.com/8613786"));
                startActivity(intent);
            } catch (Exception e) {
                Toast.makeText(this, "无法打开链接", Toast.LENGTH_SHORT).show();
            }
        });

        // 卡通人物点击彩蛋
        imgCharacter.setOnClickListener(v -> {
            Toast.makeText(this, "喵呜~不要戳(˃̶͈̀௰˂̶͈́)", Toast.LENGTH_SHORT).show();
        });
    }

    private void showMacroSettingsDialog() {
        View content = LayoutInflater.from(this).inflate(R.layout.dialog_macro_settings, null, false);

        EditText etStartup = content.findViewById(R.id.et_startup_delay);
        EditText etStep = content.findViewById(R.id.et_step_delay);
        EditText etStepMacro = content.findViewById(R.id.et_step_macro_delay);
        EditText etDrag = content.findViewById(R.id.et_drag_speed);
        EditText etHold = content.findViewById(R.id.et_hold_delay);
        SwitchCompat switchStepMacro = content.findViewById(R.id.switch_step_macro);
        SwitchCompat switchClickMacro = content.findViewById(R.id.switch_click_macro);
        Button btnRestore = content.findViewById(R.id.btn_restore_defaults);
        Button btnSave = content.findViewById(R.id.btn_save_settings);

        MacroConfig.MacroDelays current = MacroConfig.load(this);
        setNumberText(etStartup, current.startupDelayMs);
        setNumberText(etStep, current.stepDelayMs);
        setNumberText(etStepMacro, MacroConfig.getStepMacroDelayMs(this));
        setNumberText(etDrag, current.dragDurationMs);
        setNumberText(etHold, current.holdDelayMs);
        if (switchStepMacro != null) {
            switchStepMacro.setChecked(MacroConfig.isStepMacroEnabled(this));
        }
        if (switchClickMacro != null) {
            switchClickMacro.setChecked(MacroConfig.isClickCaptureEnabled(this));
        }

        AlertDialog dialog = new AlertDialog.Builder(this)
                .setView(content)
                .create();

        btnRestore.setOnClickListener(v -> {
            MacroConfig.resetToDefaults(this);
            MacroConfig.MacroDelays defaults = MacroConfig.load(this);
            setNumberText(etStartup, defaults.startupDelayMs);
            setNumberText(etStep, defaults.stepDelayMs);
            setNumberText(etStepMacro, MacroConfig.getStepMacroDelayMs(this));
            setNumberText(etDrag, defaults.dragDurationMs);
            setNumberText(etHold, defaults.holdDelayMs);
            if (switchStepMacro != null) {
                switchStepMacro.setChecked(MacroConfig.isStepMacroEnabled(this));
            }
            if (switchClickMacro != null) {
                switchClickMacro.setChecked(MacroConfig.isClickCaptureEnabled(this));
            }
            Toast.makeText(this, "已恢复初始设定", Toast.LENGTH_SHORT).show();
        });

        btnSave.setOnClickListener(v -> {
            Long startup = parseLongOrNull(etStartup);
            Long step = parseLongOrNull(etStep);
            Long stepMacro = parseLongOrNull(etStepMacro);
            Long drag = parseLongOrNull(etDrag);
            Long hold = parseLongOrNull(etHold);
            if (startup == null || step == null || stepMacro == null || drag == null || hold == null) {
                Toast.makeText(this, "请输入有效的毫秒数", Toast.LENGTH_SHORT).show();
                return;
            }

            MacroConfig.save(this, new MacroConfig.MacroDelays(startup, step, drag, hold));
            MacroConfig.setStepMacroDelayMs(this, stepMacro);
            if (switchStepMacro != null) {
                MacroConfig.setStepMacroEnabled(this, switchStepMacro.isChecked());
            }
            if (switchClickMacro != null) {
                MacroConfig.setClickCaptureEnabled(this, switchClickMacro.isChecked());
            }
            Toast.makeText(this, "已保存", Toast.LENGTH_SHORT).show();
            dialog.dismiss();
        });

        dialog.show();
    }

    private static void setNumberText(EditText editText, long value) {
        if (editText == null) return;
        editText.setText(String.valueOf(value));
        editText.setSelection(editText.getText().length());
    }

    private static Long parseLongOrNull(EditText editText) {
        if (editText == null) return null;
        String text = editText.getText() == null ? null : editText.getText().toString().trim();
        if (text == null || text.isEmpty()) return null;
        try {
            return Long.parseLong(text);
        } catch (NumberFormatException ignored) {
            return null;
        }
    }

    private boolean checkPermissionsAndStart() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            Toast.makeText(this, "请先点击上方按钮授予悬浮窗权限", Toast.LENGTH_SHORT).show();
            return false;
        }

        if (!isAccessibilityServiceEnabled()) {
            Toast.makeText(this, "请先点击上方按钮开启无障碍服务", Toast.LENGTH_SHORT).show();
            return false;
        }

        Intent serviceIntent = new Intent(this, FloatingWindowService.class);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent);
        } else {
            startService(serviceIntent);
        }
        VolumeKeyAccessibilityService.setMasterEnabled(true);
        Toast.makeText(this, "已启动悬浮窗服务", Toast.LENGTH_SHORT).show();

        updateCheckIcons();
        return true;
    }

    private void stopServiceLogic() {
        stopService(new Intent(this, FloatingWindowService.class));
        FloatingWindowService.stopService(this);
        VolumeKeyAccessibilityService.setMasterEnabled(false);
        Toast.makeText(this, "已停止悬浮窗服务", Toast.LENGTH_SHORT).show();
    }

    @Override
    protected void onResume() {
        super.onResume();
        refreshFullUI();
    }

    private void refreshFullUI() {
        boolean isServiceOn = isServiceRunning(FloatingWindowService.class);
        // 如果服务没在运行，强制关掉开关
        if (!isServiceOn && toggleServiceSwitch.isChecked()) {
            toggleServiceSwitch.setChecked(false);
        } else if (isServiceOn && !toggleServiceSwitch.isChecked()) {
            toggleServiceSwitch.setChecked(true);
        }
        updateCheckIcons();
    }

    private void updateCheckIcons() {
        boolean isAccessOn = isAccessibilityServiceEnabled();
        boolean isOverlayOn = Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(this);
        // 使用 Switch 的状态作为服务开启的依据，这样反馈最及时
        boolean isServiceOn = toggleServiceSwitch.isChecked();

        checkAccessibility.setImageResource(isAccessOn ? R.drawable.ic_check_green : R.drawable.ic_close_red);
        checkOverlay.setImageResource(isOverlayOn ? R.drawable.ic_check_green : R.drawable.ic_close_red);
        checkService.setImageResource(isServiceOn ? R.drawable.ic_check_green : R.drawable.ic_close_red);
    }

    private boolean isAccessibilityServiceEnabled() {
        AccessibilityManager manager = (AccessibilityManager) getSystemService(ACCESSIBILITY_SERVICE);
        if (manager == null) return false;
        List<AccessibilityServiceInfo> enabledServices = manager.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK);
        if (enabledServices == null) return false;
        String myPackage = getPackageName().toLowerCase();
        for (AccessibilityServiceInfo serviceInfo : enabledServices) {
            String id = serviceInfo.getId();
            if (id != null && id.toLowerCase().contains(myPackage)) {
                return true;
            }
        }
        return false;
    }

    private boolean isServiceRunning(Class<?> serviceClass) {
        if (FloatingWindowService.isRunning()) return true;
        ActivityManager manager = (ActivityManager) getSystemService(Context.ACTIVITY_SERVICE);
        if (manager == null) return false;
        for (ActivityManager.RunningServiceInfo serviceInfo : manager.getRunningServices(Integer.MAX_VALUE)) {
            if (serviceClass.getName().equals(serviceInfo.service.getClassName())) {
                return true;
            }
        }
        return false;
    }
}
