# ==========================
# TINK
# ==========================
-keep class com.google.crypto.tink.** { *; }

# ==========================
# ErrorProne annotations
# ==========================
-keep class com.google.errorprone.annotations.** { *; }

# ==========================
# javax.annotation
# ==========================
-keep class javax.annotation.** { *; }

# ==========================
# Joda-Time
# ==========================
-keep class org.joda.time.** { *; }

# ==========================
# Google Play Core (SplitInstall/Deferred Components)
# ==========================
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# ==========================
# Flutter Deferred Components
# ==========================
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }