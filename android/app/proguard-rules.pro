# Flutter Engine & Plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Flutter Local Notifications & Gson Models
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.models.** { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver { *; }

# Gson (used by flutter_local_notifications to deserialize alarms in background)
-keep class com.google.gson.** { *; }
-keepclassmembers class com.google.gson.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-dontwarn com.google.gson.**

# AndroidX Core Notification
-keep class androidx.core.app.NotificationCompat** { *; }
-keep class androidx.core.app.NotificationManagerCompat** { *; }

# Flutter Timezone
-keep class com.whelksoft.flutter_timezone.** { *; }

# Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Desugaring & Java 8+ Time API
-keep class java.time.** { *; }
-keep class j$.time.** { *; }
-dontwarn java.time.**
-dontwarn j$.**

# Preserve essential attributes for reflection, annotations, and debugging
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

