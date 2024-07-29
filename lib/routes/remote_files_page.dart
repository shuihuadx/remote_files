import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remote_files/data/configs.dart';
import 'package:remote_files/entities/remote_file.dart';
import 'package:remote_files/method_channel/remote_file_method_channel.dart';
import 'package:remote_files/network/remote_files_fetcher.dart';
import 'package:remote_files/routes/server_list_page.dart';
import 'package:remote_files/routes/theme_color_settings_page.dart';
import 'package:remote_files/routes/video_player_settings_page.dart';
import 'package:remote_files/theme/app_theme.dart';
import 'package:remote_files/utils/codec_utils.dart';
import 'package:remote_files/utils/dlna_utils.dart';
import 'package:remote_files/utils/file_utils.dart';
import 'package:remote_files/utils/process_helper.dart';
import 'package:remote_files/utils/snack_utils.dart';
import 'package:remote_files/utils/url_utils.dart';
import 'package:remote_files/widgets/dlna_devices_widget.dart';
import 'package:remote_files/widgets/loading_widget.dart';
import 'package:remote_files/widgets/reloading_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class RemoteFilesPage extends StatefulWidget {
  static String get routeName => 'remote_files_page';
  final String url;

  const RemoteFilesPage({
    super.key,
    required this.url,
  });

  @override
  State<RemoteFilesPage> createState() => _RemoteFilesPageState();
}

class _RemoteFilesPageState extends State<RemoteFilesPage> {
  /// setState时重新给_futureBuilderKey赋值,以重新刷新 FutureBuilder
  GlobalKey _futureBuilderKey = GlobalKey();
  late Future<RemoteFilesInfo> _future;
  late String url;
  bool isRootUrl = false;
  late String title;

  String getPageTitle(bool isRootUrl) {
    if (isRootUrl) {
      return Configs.getInstanceSync()
          .remoteServers
          .firstWhere(
            (remoteServer) =>
        Configs.getInstanceSync().currentServerUrl ==
            remoteServer.serverUrl,
      )
          .serverName;
    } else {
      return UrlUtils.getUrlLastPath(CodecUtils.urlDecode(url));
    }
  }

  @override
  void initState() {
    DlnaUtils.startSearch();

    url = widget.url;
    isRootUrl = Configs.getInstanceSync().currentServerUrl == url;
    title = getPageTitle(isRootUrl);
    _future = remoteFilesFetcher.fetchRemoteFiles(url);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        leading: Builder(
          builder: (BuildContext context) {
            return isRootUrl
                ? IconButton(
              icon: const Icon(
                Icons.menu,
                color: Colors.white,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            )
                : IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            );
          },
        ),
        systemOverlayStyle: AppTheme.systemOverlayStyle,
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
      drawer: Drawer(
        child: Builder(
          builder: (context) {
            return ListView(
              // Important: Remove any padding from the ListView.
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
                  child: const Text(
                    'Remote Files',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                Platform.isWindows
                    ? ListTile(
                  title: const Text('视频播放器设置'),
                  onTap: () {
                    // 视频播放器设置
                    if (mounted) {
                      Navigator.of(context)
                          .pushNamed(VideoPlayerSettingsPage.routeName);
                    }
                    return;
                  },
                )
                    : const SizedBox(),
                ListTile(
                  title: const Text('服务器管理'),
                  onTap: () {
                    // 服务器管理
                    if (mounted) {
                      // Close the drawer
                      Scaffold.of(context).closeDrawer();

                      var oldCurrentServerUrl =
                          Configs.getInstanceSync().currentServerUrl;
                      Navigator.of(context)
                          .pushNamed(ServerListPage.routeName)
                          .then((value) {
                        var currentServerUrl =
                            Configs.getInstanceSync().currentServerUrl;
                        if (oldCurrentServerUrl != currentServerUrl) {
                          setState(() {
                            _futureBuilderKey = GlobalKey();
                            _future = remoteFilesFetcher
                                .fetchRemoteFiles(currentServerUrl);
                            isRootUrl = true;
                            title = getPageTitle(isRootUrl);
                          });
                        }
                      });
                    }
                  },
                ),
                ListTile(
                  title: const Text('设置主题色'),
                  onTap: () {
                    // 设置主题色
                    if (mounted) {
                      // Close the drawer
                      Scaffold.of(context).closeDrawer();

                      Navigator.of(context)
                          .pushNamed(ThemeColorSettingsPage.routeName);
                    }
                  },
                ),
                // ListTile(
                //   title: const Text('测试'),
                //   onTap: () {
                //   },
                // ),
              ],
            );
          },
        ),
      ),
      body: PopScope(
        canPop: !isRootUrl,
        onPopInvoked: (didPop) {
          if (isRootUrl) {
            SnackUtils.showSnack(
              context,
              message: '没有上一页了',
              backgroundColor: Theme.of(context).primaryColor,
            );
          }
        },
        child: remoteFilesList(),
      ),
    );
  }

  Widget remoteFilesList() {
    return FutureBuilder(
      key: _futureBuilderKey,
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.hasData) {
          RemoteFilesInfo remoteFilesInfo = snapshot.data as RemoteFilesInfo;
          return ListView.builder(
            itemCount: remoteFilesInfo.remoteFiles.length,
            itemBuilder: (BuildContext context, int index) {
              RemoteFile remoteFile = remoteFilesInfo.remoteFiles[index];
              return GestureDetector(
                child: FileItem(
                  fileName: remoteFile.fileName,
                  url: remoteFile.url,
                  isDir: remoteFile.isDir,
                ),
                onTap: () async {
                  if (remoteFile.isDir) {
                    Navigator.of(context).pushNamed(
                      RemoteFilesPage.routeName,
                      arguments: remoteFile.url,
                    );
                  } else {
                    if (Platform.isWindows &&
                        FileUtils.isVideoFile(remoteFile.fileName)) {
                      Configs configs = Configs.getInstanceSync();
                      String videoPlayerPath = configs.videoPlayerPath;
                      if (videoPlayerPath.isEmpty) {
                        videoPlayerPath =
                        'C:/Program Files/Windows Media Player/wmplayer.exe';
                      }
                      ProcessHelper.run(
                        videoPlayerPath,
                        args: [remoteFile.url],
                      );
                    } else if (Platform.isAndroid) {
                      RemoteFileMethodChannel.launchRemoteFile(remoteFile);
                    } else {
                      if (!await launchUrl(Uri.parse(remoteFile.url))) {
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
                  }
                },
              );
            },
          );
        } else if (snapshot.hasError) {
          return ReloadingView(
            errorReason: snapshot.error.toString(),
            onPressed: () {
              setState(() {
                _futureBuilderKey = GlobalKey();
                _future = remoteFilesFetcher.fetchRemoteFiles(url);
              });
            },
          );
        } else {
          return const LoadingWidget(
            width: 100,
            height: 100,
          );
        }
      },
    );
  }
}

class FileItem extends StatelessWidget {
  final String fileName;
  final String url;
  final bool isDir;

  const FileItem({
    super.key,
    required this.fileName,
    required this.url,
    required this.isDir,
  });

  Widget getFileIcon(BuildContext context, String fileName) {
    Color themeColor = Theme.of(context).primaryColor;
    if (isDir) {
      return Icon(
        Icons.folder,
        color: themeColor,
        size: 48,
      );
    }
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
  Widget build(BuildContext context) {
    return Container(
      height: 64.0,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: getFileIcon(context, fileName),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
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
                            url,
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
                  onTapDown: (TapDownDetails details) {
                    FileType fileType = FileUtils.getFileType(fileName);
                    showMoreMenus(
                      context: context,
                      url: url,
                      position: Offset(
                        details.globalPosition.dx,
                        details.globalPosition.dy,
                      ),
                      enableDLNA: !isDir &&
                          (fileType == FileType.video ||
                              fileType == FileType.audio ||
                              fileType == FileType.image),
                      // TODO 文件下载待实现
                      // enableDownload: !isDir,
                    );
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
          )
        ],
      ),
    );
  }

  void showMoreMenus({
    required BuildContext context,
    required String url,
    required Offset position,
    bool enableDLNA = false,
    bool enableDownload = false,
  }) async {
    List<PopupMenuItem> menuItems = [];
    if (enableDLNA) {
      menuItems.add(const PopupMenuItem(
        value: 1,
        child: Text('DLNA投屏'),
      ));
    }
    if (enableDownload) {
      menuItems.add(const PopupMenuItem(
        value: 2,
        child: Text('下载到本地'),
      ));
    }
    menuItems.add(const PopupMenuItem(
      value: 3,
      child: Text('复制链接'),
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
      return;
    }
    if (value == 1) {
      // 通过DLNA投屏播放
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
                    DlnaUtils.play(device, url);
                  },
                ),
              );
            },
          );
        },
      );
      return;
    } else if (value == 2) {
      // TODO 下载到本地
      return;
    } else if (value == 3) {
      // 复制链接
      Clipboard.setData(ClipboardData(text: url));
      SnackUtils.showSnack(
        context,
        message: '已复制文件地址',
        backgroundColor: Theme.of(context).primaryColor,
      );
      return;
    }
  }
}
