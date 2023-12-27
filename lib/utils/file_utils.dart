enum FileType {
  video,
  audio,
  compress,
  image,
  unknown,
}

class FileUtils {
  static FileType getFileType(String fileName) {
    String fileExtension = getFileExtension(fileName);
    if (fileExtension.isEmpty) {
      return FileType.unknown;
    }
    if (videoFileExtensions.contains(fileExtension)) {
      return FileType.video;
    }
    if (audioFileExtensions.contains(fileExtension)) {
      return FileType.audio;
    }
    if (compressionFileExtensions.contains(fileExtension)) {
      return FileType.compress;
    }
    if(imageFileExtensions.contains(fileExtension)){
      return FileType.image;
    }
    return FileType.unknown;
  }

  static String getFileExtension(String fileName) {
    String lowerCaseFileName = fileName.toLowerCase();
    int lastIndexOfDot = lowerCaseFileName.lastIndexOf('.');
    if (lastIndexOfDot < 0) {
      return '';
    }
    return lowerCaseFileName.substring(lastIndexOfDot + 1);
  }

  static bool isVideoFile(String fileName) {
    String fileExtension = getFileExtension(fileName);
    if (fileExtension.isEmpty) {
      return false;
    }
    return videoFileExtensions.contains(fileExtension);
  }

  static bool isAudioFile(String fileName) {
    String fileExtension = getFileExtension(fileName);
    if (fileExtension.isEmpty) {
      return false;
    }
    return audioFileExtensions.contains(fileExtension);
  }

  static bool isCompressFile(String fileName) {
    String fileExtension = getFileExtension(fileName);
    if (fileExtension.isEmpty) {
      return false;
    }
    return compressionFileExtensions.contains(fileExtension);
  }

  static bool isImageFile(String fileName) {
    String fileExtension = getFileExtension(fileName);
    if (fileExtension.isEmpty) {
      return false;
    }
    return imageFileExtensions.contains(fileExtension);
  }
}

const Set<String> videoFileExtensions = {
  "3g2",
  "3gp",
  "avi",
  "flv",
  "h264",
  "m4v",
  "mkv",
  "mov",
  "mp4",
  "mpg",
  "mpeg",
  "rm",
  "swf",
  "vob",
  "wmv",
  "webm",
  "rmvb",
};

const Set<String> audioFileExtensions = {
  '3gp', // 用于3G移动电话
  'aa', // Audible audiobook file
  'aac', // 高级音频编码
  'aiff', // 音频交换文件格式
  'alac', // Apple无损
  'amr', // 自适应多速率
  'ape', // Monkey's Audio
  'au', // Sun Microsystems的音频格式
  'awb', // AMR-WB audio file
  'dct', // 可变速度录音
  'dss', // Digital Speech Standard
  'dvf', // Sony Digital Voice file
  'flac', // 自由无损音频编码器
  'gsm', // Global System for Mobile Audio file
  'iklax', // iKlax format
  'ivs', // 3D sound file used by some video games
  'm4a', // MPEG-4音频
  'm4b', // MPEG-4 audiobook file
  'm4p', // MPEG-4 protected audio file
  'mmf', // Samsung音乐格式
  'mp3', // MPEG-1音频层3
  'mpc', // Musepack
  'msv', // Memory Stick Voice file
  'nmf', // NICE Media Player audio file format
  'ogg', // Ogg Vorbis
  'oga', // Ogg Vorbis Audio
  'opus', // Opus Interactive Audio Codec
  'ra', // Real Audio
  'ram', // Real Audio Metadata
  'sln', // Raw PCM data from Asterisk PBX
  'tta', // 真正的音频
  'vox', // Dialogic ADPCM
  'wav', // 波形音频文件格式
  'wma', // Windows Media Audio
  'webm', // WebM audio files
  '8svx', // 8-Bit Sampled Voice
  'cda', // CD Audio track
};

const Set<String> compressionFileExtensions = {
  'zip',
  'rar',
  '7z',
  'tar',
  'gz',
  'bz2',
  'xz',
  'tar.gz',
  'tar.bz2',
  'tar.xz',
  'tar.7z',
  'tgz',
  'tbz2',
  'txz',
  'sit',
  'sitx',
  'zipx',
  'jar',
  'war',
  'ear',
  'cab',
  'iso',
  'bz',
  'z'
};

const Set<String> imageFileExtensions = {
  'jpeg',
  'jpg',
  'png',
  'gif',
  'bmp',
  'tif',
  'tiff',
  'webp',
  'svg',
  'ico',
  'psd',
  'ai',
  'eps',
  'raw',
  'heic',
  'heif',
  'cr2',
  'nef',
  'dng',
  'orf',
  'arw',
  'rw2',
  'srw',
  'pef',
  'raf',
  'rwl',
  '3fr',
  'mrw',
  'sr2',
  'mef',
  'mos',
  'kdc',
};
