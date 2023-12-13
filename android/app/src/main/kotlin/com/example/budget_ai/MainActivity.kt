package com.tilakpuli.budget_ai

import io.flutter.embedding.android.FlutterActivity
import com.google.firebase.appcheck.appCheck
import com.google.firebase.appcheck.playintegrity.PlayIntegrityAppCheckProviderFactory
import com.google.firebase.Firebase
import com.google.firebase.initialize


class MainActivity: FlutterActivity() {
    private fun init() {
        // [START appcheck_initialize]
        Firebase.initialize(context = this)
        Firebase.appCheck.installAppCheckProviderFactory(
            PlayIntegrityAppCheckProviderFactory.getInstance(),
        )
        // [END appcheck_initialize]
    }
}
