import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remote_files/app.dart';
import 'package:remote_files/data/configs.dart';
import 'package:remote_files/data/file_download_manager.dart';
import 'package:remote_files/method_channel/remote_file_method_channel.dart';
import 'package:remote_files/routes/video_player_page.dart';
import 'package:remote_files/theme/app_theme.dart';
import 'package:remote_files/utils/dlna_utils.dart';
import 'package:remote_files/utils/file_utils.dart';
import 'package:remote_files/utils/process_helper.dart';
import 'package:remote_files/utils/snack_utils.dart';
import 'package:remote_files/widgets/dlna_devices_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class DownloadManagerPage extends StatefulWidget {
  static String get routeName => 'download_manager_page';

  const DownloadManagerPage({super.key});

  @override
  State<DownloadManagerPage> createState() => _DownloadManagerPageState();
}

class _DownloadManagerPageState extends State<DownloadManagerPage> {
  late Configs configs;
  List<FileDownloadStatus> data = fileDownloadManager.getAll();

  void _init() async {}

  @override
  void initState() {
    configs = Configs.getInstanceSync();
    _init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: AppTheme.systemOverlayStyle,
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
        title: const Text(
          '下载管理',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
      body: ListView.separated(
        itemBuilder: (BuildContext context, int index) {
          FileDownloadStatus item = data[index];
          String fileName = item.fileDownloadRecord.fileName;
          String localPath = item.fileDownloadRecord.localPath;
          return InkWell(
            focusColor: Theme.of(context).colorScheme.primaryContainer,
            onTap: () async {
              if (!item.fileDownloadRecord.complete) {
                SnackUtils.showSnack(
                  context,
                  message: '下载未完成',
                  backgroundColor: Theme.of(context).primaryColor,
                );
                return;
              }
              bool isVideoFile = FileUtils.isVideoFile(fileName);
              if (isVideoFile) {
                if ((App.isAndroid && configs.useInnerPlayer) || App.isIOS || App.isMacOS) {
                  // 播放本地视频
                  Navigator.of(context).pushNamed(
                    VideoPlayerPage.routeName,
                    arguments: localPath,
                  );
                  return;
                }
              }
              if (App.isWindows && isVideoFile) {
                String videoPlayerPath = configs.videoPlayerPath;
                if (videoPlayerPath.isEmpty) {
                  videoPlayerPath = 'C:/Program Files/Windows Media Player/wmplayer.exe';
                }
                ProcessHelper.run(
                  videoPlayerPath,
                  args: [localPath],
                );
              } else if (App.isAndroid) {
                try {
                  await RemoteFileMethodChannel.launchRemoteFile(
                    fileName: fileName,
                    url: localPath,
                  );
                } catch (e) {
                  if (mounted) {
                    SnackUtils.showSnack(
                      context,
                      message: isVideoFile ? '调用外部播放器失败, 请尝试使用内置播放器' : '无法打开文件, 请先在设备上安装支持打开此文件的App',
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 2),
                    );
                  }
                }
              } else {
                if (!await launchUrl(Uri.file(localPath))) {
                  if (mounted) {
                    SnackUtils.showSnack(
                      context,
                      message: '无法打开文件, 请先在设备上安装支持打开此文件的App',
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 2),
                    );
                  }
                }
              }
            },
            child: FileItem(
              fileDownloadStatus: item,
              onDelete: () {
                if (mounted) {
                  setState(() {
                    data.removeAt(index);
                  });
                }
              },
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return const Divider(
            color: Color(0xFFE5E5E5),
            indent: 1,
            height: 0,
          );
        },
        itemCount: data.length,
      ),
    );
  }
}

class FileItem extends StatefulWidget {
  final FileDownloadStatus fileDownloadStatus;
  final Function() onDelete;

  const FileItem({
    super.key,
    required this.fileDownloadStatus,
    required this.onDelete,
  });

  @override
  State<FileItem> createState() => _FileItemState();
}

class _FileItemState extends State<FileItem> {
  Widget getFileIcon(BuildContext context, String fileName) {
    Color themeColor = Theme.of(context).primaryColor;
    switch (FileUtils.getFileType(fileName)) {
      case FileType.video:
        return Icon(
          Icons.ondemand_video,
          color: themeColor,
          size: 48,
        );
      case FileType.audio:
        return Icon(
          Icons.music_note,
          color: themeColor,
          size: 48,
        );
      case FileType.compress:
        return Icon(
          Icons.folder_zip,
          color: themeColor,
          size: 48,
        );
      case FileType.image:
        return Icon(
          Icons.image,
          color: themeColor,
          size: 48,
        );
      default:
        return Icon(
          Icons.insert_drive_file,
          color: themeColor,
          size: 48,
        );
    }
  }

  @override
  void initState() {
    if (!widget.fileDownloadStatus.fileDownloadRecord.complete) {
      widget.fileDownloadStatus.progressCallback = (int downloadBytes, int totalBytes) {
        if (mounted) {
          setState(() {});
        }
      };
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    FileDownloadStatus item = widget.fileDownloadStatus;
    String fileName = item.fileDownloadRecord.fileName;
    String fileUrl = item.fileDownloadRecord.fileUrl;
    bool isComplete = item.fileDownloadRecord.complete;
    double fileSize = item.fileDownloadRecord.fileBytes.toDouble();
    double progress = isComplete
        ? 1
        : item.fileDownloadRecord.downloadBytes.toDouble() / (fileSize == 0 ? 1 : fileSize);
    return SizedBox(
      height: 64.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: getFileIcon(context, fileName),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(
                      left: 10,
                      top: 10,
                      right: 0,
                      bottom: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xff333333),
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            fileUrl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xff999999),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTapDown: (TapDownDetails details) async {
                    FileType fileType = FileUtils.getFileType(fileName);
                    int? value = await showMoreMenus(
                      context: context,
                      fileDownloadStatus: item,
                      position: Offset(
                        details.globalPosition.dx,
                        details.globalPosition.dy,
                      ),
                      enableDLNA: (fileType == FileType.video ||
                          fileType == FileType.audio ||
                          fileType == FileType.image),
                    );
                    if (value == 3) {
                      widget.onDelete.call();
                    }
                  },
                  child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.more_vert,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Visibility(
            visible: !isComplete,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
                value: progress,
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<int?> showMoreMenus({
    required BuildContext context,
    required FileDownloadStatus fileDownloadStatus,
    required Offset position,
    bool enableDLNA = false,
  }) async {
    String fileUrl = fileDownloadStatus.fileDownloadRecord.fileUrl;
    List<PopupMenuItem> menuItems = [];
    if (enableDLNA) {
      menuItems.add(PopupMenuItem(
        value: 1,
        child: const Text('DLNA投屏'),
        onTap: () {
          showModalBottomSheet(
            context: context,
            useSafeArea: true,
            showDragHandle: true,
            isScrollControlled: true,
            builder: (context) {
              return DraggableScrollableSheet(
                expand: false,
                builder: (context, scrollController) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    child: DlnaDevicesWidget(
                      onDeviceSelected: (device) {
                        DlnaUtils.play(device, fileDownloadStatus.fileDownloadRecord.fileUrl);
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ));
    }
    menuItems.add(PopupMenuItem(
      value: 2,
      child: const Text('复制链接'),
      onTap: () {
        Clipboard.setData(ClipboardData(text: fileUrl));
        SnackUtils.showSnack(
          context,
          message: '已复制文件地址',
          backgroundColor: Theme.of(context).primaryColor,
        );
      },
    ));
    if (!fileDownloadStatus.fileDownloadRecord.complete) {
      if (fileDownloadStatus.isDownloading) {
        menuItems.add(PopupMenuItem(
          child: const Text('暂停下载'),
          onTap: () {
            fileDownloadManager.cancel(fileUrl: fileUrl);
          },
        ));
      } else {
        menuItems.add(PopupMenuItem(
          child: const Text('开始下载'),
          onTap: () {
            fileDownloadManager.startDownload(
              fileName: fileDownloadStatus.fileDownloadRecord.fileName,
              fileUrl: fileUrl,
            );
          },
        ));
      }
    }
    menuItems.add(PopupMenuItem(
      value: 3,
      child: const Text('删除'),
      onTap: () {
        fileDownloadManager.delete(fileUrl: fileUrl);
      },
    ));

    dynamic value = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        0,
        0,
      ),
      items: menuItems,
      elevation: 8.0,
    );
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    return null;
  }
}
