# Flutter-specific ProGuard rules
# Keep Flutter engine and plugin classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep entry point
-keep class nl.deelmarkt.deelmarkt.MainActivity { *; }
