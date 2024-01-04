import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remote_files/data/configs.dart';
import 'package:remote_files/entities/remote_file.dart';
import 'package:remote_files/network/remote_files_fetcher.dart';
import 'package:remote_files/routes/add_server_page.dart';
import 'package:remote_files/routes/theme_color_settings_page.dart';
import 'package:remote_files/routes/video_player_settings_page.dart';
import 'package:remote_files/theme/app_theme.dart';
import 'package:remote_files/utils/codec_utils.dart';
import 'package:remote_files/utils/file_utils.dart';
import 'package:remote_files/utils/process_helper.dart';
import 'package:remote_files/utils/snack_utils.dart';
import 'package:remote_files/utils/url_utils.dart';
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
            (remoteServer) => Configs.getInstanceSync().currentServerUrl == remoteServer.serverUrl,
          )
          .serverName;
    } else {
      return UrlUtils.getUrlLastPath(CodecUtils.urlDecode(url));
    }
  }

  @override
  void initState() {
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
        leading: isRootUrl
            ? IconButton(
                icon: const Icon(
                  Icons.menu,
                  color: Colors.white,
                ),
                onPressed: () async {
                  Configs configs = Configs.getInstanceSync();
                  List<PopupMenuItem> menuItems = [];
                  for (var remoteServer in configs.remoteServers) {
                    if (remoteServer.serverUrl != configs.currentServerUrl) {
                      menuItems.add(PopupMenuItem(
                        value: remoteServer.serverUrl,
                        child: Text(remoteServer.serverName),
                      ));
                    }
                  }
                  menuItems.add(const PopupMenuItem(
                    value: 1,
                    child: Text('添加服务器'),
                  ));
                  if (Platform.isWindows) {
                    menuItems.add(const PopupMenuItem(
                      value: 2,
                      child: Text('视频播放器设置'),
                    ));
                  }
                  menuItems.add(const PopupMenuItem(
                    value: 3,
                    child: Text('设置主题色'),
                  ));

                  dynamic value = await showMenu(
                    context: context,
                    position: const RelativeRect.fromLTRB(0, 80, 0, 0),
                    items: menuItems,
                    elevation: 8.0,
                  );
                  if (value == null) {
                    return;
                  }
                  if (value == 1) {
                    // 添加服务器
                    if (mounted) {
                      Navigator.of(context).pushNamed(AddServerPage.routeName);
                    }
                    return;
                  } else if (value == 2) {
                    // 添加服务器
                    if (mounted) {
                      Navigator.of(context).pushNamed(VideoPlayerSettingsPage.routeName);
                    }
                    return;
                  } else if (value == 3) {
                    // 设置主题色
                    if (mounted) {
                      Navigator.of(context).pushNamed(ThemeColorSettingsPage.routeName);
                    }
                    return;
                  } else {
                    configs.currentServerUrl = value;
                    await configs.save();
                    setState(() {
                      _futureBuilderKey = GlobalKey();
                      _future = remoteFilesFetcher.fetchRemoteFiles(value);
                      isRootUrl = true;
                      title = getPageTitle(isRootUrl);
                    });
                  }
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
              ),
        automaticallyImplyLeading: !isRootUrl,
        systemOverlayStyle: AppTheme.systemOverlayStyle,
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
      body: isRootUrl
          ? WillPopScope(
              onWillPop: () async {
                if (isRootUrl) {
                  SnackUtils.showSnack(
                    context,
                    message: '没有上一页了',
                    backgroundColor: Theme.of(context).primaryColor,
                  );
                  return false;
                }
                return true;
              },
              child: remoteFilesList(),
            )
          : remoteFilesList(),
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
                    if (Platform.isWindows && FileUtils.isVideoFile(remoteFile.fileName)) {
                      Configs configs = Configs.getInstanceSync();
                      String videoPlayerPath = configs.videoPlayerPath;
                      if (videoPlayerPath.isEmpty) {
                        videoPlayerPath = 'C:/Program Files/Windows Media Player/wmplayer.exe';
                      }
                      ProcessHelper.run(
                        videoPlayerPath,
                        args: [remoteFile.url],
                      );
                      return;
                    }
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

  FileItem({
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
    Icon(
      Icons.image,
      color: themeColor,
      size: 48,
    );
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
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: url));
                    SnackUtils.showSnack(
                      context,
                      message: '已复制文件地址',
                      backgroundColor: Theme.of(context).primaryColor,
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(
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
}
