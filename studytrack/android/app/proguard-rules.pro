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
