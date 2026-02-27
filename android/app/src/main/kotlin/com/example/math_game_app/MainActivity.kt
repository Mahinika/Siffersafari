package com.example.math_game_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterShellArgs

class MainActivity : FlutterActivity() {
	override fun getFlutterShellArgs(): FlutterShellArgs {
		val baseArgs = FlutterShellArgs.fromIntent(intent)
		val combined = mutableListOf<String>()
		combined.addAll(baseArgs.toArray().toList())
		combined.add("--enable-impeller=false")

		return FlutterShellArgs(combined.toTypedArray())
	}
}
