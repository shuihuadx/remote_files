package org.dx.remotefiles.remote_files

import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine
import android.content.Intent
import android.net.Uri

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val methodChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "RemoteFileMethodChannel")
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "launchRemoteFile" -> {
                    val arguments: HashMap<String, Any> = call.arguments as HashMap<String, Any>
                    val url = arguments["url"] as String?
                    val fileType = arguments["fileType"] as String?
                    if (url == null || fileType == null) {
                        result.error(
                            "launchUrl",
                            "url or fileType is null, url=${url},fileType${fileType}",
                            null
                        )
                        return@setMethodCallHandler
                    }
                    val intent = Intent(Intent.ACTION_VIEW)
                    val uri = Uri.parse(url)
                    if (fileType == "video") {
                        intent.setDataAndType(uri, "video/*")
                    } else if (fileType == "audio") {
                        intent.setDataAndType(uri, "audio/*")
                    } else if (fileType == "compress") {
                        intent.setDataAndType(uri, "application/*")
                    } else if (fileType == "image") {
                        intent.setDataAndType(uri, "image/*")
                    } else {
                        intent.setDataAndType(uri, "application/*")
                    }
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(intent)

                    result.success(true)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
