# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Play Services & Google Sign-In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Hive
-keep class io.flutter.plugins.hive.** { *; }
-keep class io.leancode.hive.** { *; }

# Encrypt & Crypto
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# Local Auth & Biometric
-keep class androidx.biometric.** { *; }
-dontwarn androidx.biometric.**

# Keep models and entities
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses

# Play Core deferred components
-dontwarn com.google.android.play.core.**

