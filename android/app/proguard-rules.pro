# ========================================
# Flutter Wrapper
# ========================================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.android.FlutterFragment
-dontwarn io.flutter.embedding.android.FlutterFragmentActivity
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# ========================================
# Preserve annotations
# ========================================
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# ========================================
# Firebase
# ========================================
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firebase Crashlytics
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keep class com.google.firebase.crashlytics.** { *; }
-dontwarn com.google.firebase.crashlytics.**

# Firebase Analytics
-keep class com.google.android.gms.measurement.** { *; }

# Firebase Performance
-keep class com.google.firebase.perf.** { *; }

# Firebase Remote Config
-keep class com.google.firebase.remoteconfig.** { *; }

# Firebase Messaging (FCM)
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }

# ========================================
# ML Kit Vision & Text Recognition
# ========================================
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.vision.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.internal.mlkit_vision_text.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**

# ========================================
# Play Core & GMS
# ========================================
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.gms.internal.**
-dontwarn com.google.android.gms.common.**

# ========================================
# Camera & Image Picker
# ========================================
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# ========================================
# Gson (if used)
# ========================================
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# ========================================
# PDF Libraries
# ========================================
-keep class com.artifex.** { *; }
-keep class org.apache.pdfbox.** { *; }
-dontwarn com.artifex.**
-dontwarn org.apache.pdfbox.**

# ========================================
# Riverpod
# ========================================
-keep class * extends com.riverpod.** { *; }
-keepclassmembers class * extends com.riverpod.** { *; }

# ========================================
# OkHttp & Retrofit (if used)
# ========================================
-dontwarn okhttp3.**
-dontwarn retrofit2.**
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }

# ========================================
# Dio (HTTP client)
# ========================================
-keep class io.flutter.plugins.** { *; }

# ========================================
# SQLite & Hive
# ========================================
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }
-keep class net.bytebuddy.** { *; }
-dontwarn net.bytebuddy.**

# ========================================
# Keep model classes
# ========================================
-keep class com.bizagent.app.models.** { *; }
-keepclassmembers class com.bizagent.app.models.** { *; }

# ========================================
# Keep enums
# ========================================
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ========================================
# Keep Parcelables
# ========================================
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# ========================================
# Keep Serializable
# ========================================
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ========================================
# Remove logging in release
# ========================================
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}

# ========================================
# Native methods
# ========================================
-keepclasseswithmembernames class * {
    native <methods>;
}

# ========================================
# Keep custom views
# ========================================
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
    public void set*(...);
}

# ========================================
# Keep JavaScript interfaces
# ========================================
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# ========================================
# WorkManager
# ========================================
-keep class androidx.work.** { *; }
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.ListenableWorker

# ========================================
# General
# ========================================
-dontwarn java.lang.invoke.*
-dontwarn **.R$*
