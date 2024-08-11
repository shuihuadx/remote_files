package org.dx.remotefiles.remote_files

import android.content.Context
import android.net.Uri
import androidx.core.content.FileProvider
import java.io.File

public class RemoteFileProvider : FileProvider() {
    companion object {
        fun getUriForFile(context: Context, file: File): Uri {
            return FileProvider.getUriForFile(
                context,
                context.getPackageName() + ".remotefileprovider",
                file
            );
        }
    }
}