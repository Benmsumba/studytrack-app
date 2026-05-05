# Keep Flutter and plugin registration classes.
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Preserve the Android entry points referenced from the manifest.
-keep class com.studytrack.app.MainActivity { *; }
-keep class com.studytrack.app.StudyTrackWidgetProvider { *; }

# Keep metadata that reflection-heavy libraries rely on.
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# Strip standard Android log calls from release builds.
-assumenosideeffects class android.util.Log {
    public static *** v(...);
    public static *** d(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
    public static *** wtf(...);
}

# Preserve home_widget provider classes.
-keep class es.antonborri.home_widget.** { *; }

# google_generative_ai — reflection-heavy; keep all public API surface.
-keep class com.google.ai.** { *; }
-keep class com.google.generativeai.** { *; }
-keepnames class com.google.protobuf.** { *; }
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.ai.**
-dontwarn com.google.generativeai.**

# supabase_flutter / postgrest / realtime — OkHttp + Kotlin serialization.
-keep class io.supabase.** { *; }
-keep class io.github.jan.supabase.** { *; }
-keepclassmembers class * {
    @kotlinx.serialization.SerialName <fields>;
}
-keep @kotlinx.serialization.Serializable class * { *; }
-dontwarn io.supabase.**
-dontwarn io.github.jan.supabase.**

# OkHttp (transitive dep of supabase_flutter network layer).
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# Google Play Core library (for split installs and app updates).
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
