# Flutter-specific ProGuard rules

# Keep Flutter engine and plugin classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep entry point
-keep class nl.deelmarkt.deelmarkt.MainActivity { *; }

# Play Core — referenced by Flutter engine for deferred components but not
# included in the classpath. Safe to suppress since we don't use deferred
# component loading.
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
