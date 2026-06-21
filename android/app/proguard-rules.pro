# Play Core stubs not needed in F-Droid / sideload builds
-dontwarn com.google.android.play.**

# Keep Flutter secure storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Keep vibration plugin
-keep class com.tanguy.planchon.vibration.** { *; }

# Keep flutter_local_notifications + its Gson models (#2 daily reminders)
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# Prevent stripping of model classes used in JSON serialisation
-keepattributes *Annotation*
-keepclassmembers class ** {
    @com.google.gson.annotations.SerializedName <fields>;
}
