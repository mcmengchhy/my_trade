# Flutter Proguard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.internal.** { *; }
-keep class io.flutter.provider.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Native Android Application & Widget Classes
-keep class com.example.task_game.** { *; }
-keep class com.tradejourney.app.** { *; }

# Keep Home Widget plugin classes
-keep class es.ximu.home_widget.** { *; }
-keep class id.flutter.home_widget.** { *; }

# Preserve JSON / Data model attributes
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Suppress Play Core warnings for deferred components
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
