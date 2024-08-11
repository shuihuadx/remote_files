package org.dx.remotefiles.remote_files

import android.content.Intent
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine
import java.io.File

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
                    val uri = if (url.startsWith("http")) {
                        Uri.parse(url)
                    } else {
                        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            RemoteFileProvider.getUriForFile(this@MainActivity, File(url))
                        } else {
                            Uri.fromFile(File(url))
                        }
                    }
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
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
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
