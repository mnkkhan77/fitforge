# Flutter wrapper
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Flutter secure storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Keep vibration plugin
-keep class com.tanguy.planchon.vibration.** { *; }

# Prevent stripping of model classes used in JSON serialisation
-keepattributes *Annotation*
-keepclassmembers class ** {
    @com.google.gson.annotations.SerializedName <fields>;
}
