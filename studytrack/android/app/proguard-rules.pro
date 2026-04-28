# Keep Flutter and plugin registration classes.
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Preserve home_widget provider and generated R references.
-keep class es.antonborri.home_widget.** { *; }
-keep class com.studytrack.studytrack.StudyTrackWidgetProvider { *; }

# Keep model classes serialized from JSON maps.
-keepclassmembers class com.studytrack.studytrack.** {
    <fields>;
}
