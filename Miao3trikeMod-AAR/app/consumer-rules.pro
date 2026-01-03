# 保留库中的所有类和方法
-keep class com.miao3strikemod.matches.** { *; }
-keepclassmembers class com.miao3strikemod.matches.** { *; }

# 保留无障碍服务相关
-keep class * extends android.accessibilityservice.AccessibilityService { *; }
-keepclassmembers class * extends android.accessibilityservice.AccessibilityService { *; }

# 保留服务
-keepclasseswithmembers class * extends android.app.Service { *; }

# 保留R文件
-keepclassmembers class **.R$* {
    public static <fields>;
}