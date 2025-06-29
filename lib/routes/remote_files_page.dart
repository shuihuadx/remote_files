import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remote_files/app.dart';
import 'package:remote_files/data/configs.dart';
import 'package:remote_files/data/file_download_manager.dart';
import 'package:remote_files/entities/remote_file.dart';
import 'package:remote_files/network/network_helper.dart';
import 'package:remote_files/routes/download_manager_page.dart';
import 'package:remote_files/routes/file_upload_page.dart';
import 'package:remote_files/routes/server_list_page.dart';
import 'package:remote_files/routes/theme_color_settings_page.dart';
import 'package:remote_files/routes/video_player_settings_page.dart';
import 'package:remote_files/theme/app_theme.dart';
import 'package:remote_files/utils/codec_utils.dart';
import 'package:remote_files/utils/dlna_utils.dart';
import 'package:remote_files/utils/file_click_handle.dart';
import 'package:remote_files/utils/file_utils.dart';
import 'package:remote_files/utils/snack_utils.dart';
import 'package:remote_files/utils/url_utils.dart';
import 'package:remote_files/widgets/dlna_devices_widget.dart';
import 'package:remote_files/widgets/loading_widget.dart';
import 'package:remote_files/widgets/reloading_widget.dart';
import 'package:remote_files/widgets/widget_utils.dart';

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

enum _Status {
  loading,
  error,
  success,
}

class _RemoteFilesPageState extends State<RemoteFilesPage> {
  late Configs configs;
  _Status _status = _Status.loading;
  String _errorReason = '';
  RemoteFilesInfo remoteFilesInfo = RemoteFilesInfo(
    title: 'default',
    remoteFiles: [],
    htmlResponse: '',
  );
  bool enableDownload = !App.isWeb;
  bool enableFileManager = true;
  late String url;
  bool isRootUrl = false;
  late String title;
  int lastClickBackTimestamp = 0;

  String getPageTitle(bool isRootUrl) {
    if (isRootUrl) {
      return configs.remoteServers
          .firstWhere(
            (remoteServer) => configs.currentServerUrl == remoteServer.serverUrl,
          )
          .serverName;
    } else {
      return UrlUtils.getUrlLastPath(CodecUtils.urlDecode(url));
    }
  }

  void setLoadUrl(
    String url, {
    bool enableCache = true,
  }) {
    this.url = url;
    _status = _Status.loading;
    if (mounted) {
      setState(() {});
    }

    if (enableCache) {
      // 本地缓存
      networkHelper.fetchCachedRemoteFiles(url).then((RemoteFilesInfo? value) {
        if (mounted && value != null && _status != _Status.success) {
          setState(() {
            remoteFilesInfo = value;
            _status = _Status.success;
          });
        }
      });
    }

    // 远端数据
    networkHelper.fetchRemoteFiles(url).then((RemoteFilesInfo value) {
      if (mounted) {
        if (_status != _Status.success || remoteFilesInfo.htmlResponse != value.htmlResponse) {
          setState(() {
            remoteFilesInfo = value;
            _status = _Status.success;
          });
        }
      }
    }).onError((error, stackTrace) {
      // 本地缓存没有数据, 且网络请求失败的情况, 触发 snapshot.hasError 条件
      if (mounted && _status != _Status.success) {
        setState(() {
          _errorReason = error.toString();
          _status = _Status.error;
        });
      }
    });
  }

  void _initConfigByAndroidTv() async {
    if (await App.isAndroidTv()) {
      enableDownload = false;
      enableFileManager = false;
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    configs = Configs.getInstanceSync();
    _initConfigByAndroidTv();

    url = widget.url;
    isRootUrl = configs.currentServerUrl == widget.url;
    title = getPageTitle(isRootUrl);

    setLoadUrl(widget.url);
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
        actions: [
          Visibility(
            visible: _status != _Status.loading,
            child: IconButton(
              icon: const Icon(
                Icons.refresh,
                color: Colors.white,
              ),
              onPressed: () {
                setLoadUrl(url, enableCache: false);
              },
            ),
          )
        ],
        systemOverlayStyle: AppTheme.systemOverlayStyle,
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
      floatingActionButton: enableFileManager
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  FileUploadPage.routeName,
                  arguments: url.substring(configs.currentServerUrl.length),
                );
              },
              tooltip: 'upload',
              child: const Icon(Icons.upload),
            )
          : null,
      drawer: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                App.isWindows || App.isAndroid
                    ? ListTile(
                        title: Text(
                          '视频播放器设置',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        onTap: () {
                          // 视频播放器设置
                          if (mounted) {
                            Scaffold.of(context).closeDrawer();
                            Navigator.of(context).pushNamed(VideoPlayerSettingsPage.routeName);
                          }
                          return;
                        },
                      )
                    : const SizedBox(),
                ListTile(
                  title: Text(
                    '服务器管理',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  onTap: () {
                    // 服务器管理
                    if (mounted) {
                      // Close the drawer
                      Scaffold.of(context).closeDrawer();

                      var oldCurrentServerUrl = configs.currentServerUrl;
                      Navigator.of(context).pushNamed(ServerListPage.routeName).then((value) {
                        var currentServerUrl = configs.currentServerUrl;
                        if (oldCurrentServerUrl != currentServerUrl) {
                          setState(() {
                            setLoadUrl(currentServerUrl);
                            isRootUrl = true;
                            title = getPageTitle(isRootUrl);
                          });
                        }
                      });
                    }
                  },
                ),
                enableDownload
                    ? ListTile(
                        title: Text(
                          '下载管理',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        onTap: () {
                          // 服务器管理
                          if (mounted) {
                            Scaffold.of(context).closeDrawer();
                            Navigator.of(context).pushNamed(DownloadManagerPage.routeName);
                          }
                        },
                      )
                    : const SizedBox(),
                ListTile(
                  title: Text(
                    '设置主题色',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  onTap: () {
                    // 设置主题色
                    if (mounted) {
                      // Close the drawer
                      Scaffold.of(context).closeDrawer();

                      Navigator.of(context).pushNamed(ThemeColorSettingsPage.routeName);
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
      body: PopScope(
        canPop: !isRootUrl,
        onPopInvoked: (didPop) {
          if (!didPop) {
            int timestamp = DateTime.now().millisecondsSinceEpoch;
            if (timestamp - lastClickBackTimestamp < 1000) {
              // 1秒内按两次返回将会, 退出App(此方法仅适用于Android, 也只有 Android 有此需求)
              SystemNavigator.pop();
            } else {
              lastClickBackTimestamp = timestamp;
              SnackUtils.showSnack(
                context,
                message: '没有上一页了，再次返回将退出应用',
                backgroundColor: Theme.of(context).primaryColor,
              );
            }
          }
        },
        child: remoteFilesList(),
      ),
    );
  }

  Widget remoteFilesList() {
    if (_status == _Status.error) {
      return ReloadingView(
        errorReason: _errorReason,
        onPressed: () {
          setState(() {
            setLoadUrl(url);
          });
        },
      );
    } else if (_status == _Status.loading) {
      return const LoadingWidget(
        width: 100,
        height: 100,
      );
    } else {
      return ListView.builder(
        itemCount: remoteFilesInfo.remoteFiles.length,
        itemBuilder: (BuildContext context, int index) {
          RemoteFile remoteFile = remoteFilesInfo.remoteFiles[index];
          return InkWell(
            focusColor: Theme.of(context).colorScheme.primaryContainer,
            onTap: () async {
              if (remoteFile.isDir) {
                Navigator.of(context).pushNamed(
                  RemoteFilesPage.routeName,
                  arguments: remoteFile.url,
                );
              } else {
                FileClickHandle.handleFileClick(
                  context: context,
                  fileName: remoteFile.fileName,
                  fileUrl: remoteFile.url,
                );
              }
            },
            child: FileItem(
              fileName: remoteFile.fileName,
              url: remoteFile.url,
              isDir: remoteFile.isDir,
              enableDownload: enableDownload,
              onDelete: () {
                remoteFilesInfo.remoteFiles.removeAt(index);
                if (mounted) {
                  setState(() {});
                }
              },
            ),
          );
        },
      );
    }
  }
}

class FileItem extends StatelessWidget {
  final String fileName;
  final String url;
  final bool isDir;
  final bool enableDownload;
  final Function()? onDelete;

  const FileItem({
    super.key,
    required this.fileName,
    required this.url,
    required this.isDir,
    required this.enableDownload,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: WidgetUtils.getFileIcon(
              context: context,
              fileName: fileName,
              isDir: isDir,
            ),
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
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTapDown: (TapDownDetails details) async {
                    FileType fileType = FileUtils.getFileType(fileName);
                    // 是否已经存在下载记录了
                    bool existDownloadRecord = fileDownloadManager.get(url) != null;
                    showMoreMenus(
                        context: context,
                        url: url,
                        position: Offset(
                          details.globalPosition.dx,
                          details.globalPosition.dy,
                        ),
                        enableDLNA: !App.isWeb &&
                            !(await App.isAndroidTv()) &&
                            !isDir &&
                            (fileType == FileType.video ||
                                fileType == FileType.audio ||
                                fileType == FileType.image),
                        enableDownload: !isDir && enableDownload && !existDownloadRecord,
                        enableDelete: !await App.isAndroidTv(),
                        onDelete: () {
                          onDelete?.call();
                        });
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
    bool enableDelete = false,
    Function()? onDelete,
  }) async {
    List<PopupMenuItem> menuItems = [];
    if (enableDLNA) {
      menuItems.add(PopupMenuItem(
        value: 1,
        child: const Text('DLNA投屏'),
        onTap: () {
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
        },
      ));
    }
    if (enableDownload) {
      menuItems.add(PopupMenuItem(
        value: 2,
        onTap: () {
          fileDownloadManager.startDownload(
            fileName: fileName,
            fileUrl: url,
          );
          SnackUtils.showSnack(
            context,
            message: '已添加到下载队列',
            backgroundColor: Theme.of(context).primaryColor,
          );
        },
        child: const Text('下载到本地'),
      ));
    }
    menuItems.add(PopupMenuItem(
      value: 3,
      child: const Text('复制链接'),
      onTap: () {
        // 复制链接
        Clipboard.setData(ClipboardData(text: url));
        SnackUtils.showSnack(
          context,
          message: '已复制文件地址',
          backgroundColor: Theme.of(context).primaryColor,
        );
      },
    ));

    if (enableDelete) {
      menuItems.add(PopupMenuItem(
        onTap: () async {
          String hostServerUrl = Configs.getInstanceSync().currentServerUrl;
          try {
            await networkHelper.deleteRemoteFile(
              remotePath: url.substring(hostServerUrl.length),
              hostServerUrl: hostServerUrl,
            );
            onDelete?.call();
            SnackUtils.showSnack(
              context,
              message: '文件已删除',
              backgroundColor: Theme.of(context).primaryColor,
            );
          } on Exception catch (_) {
            SnackUtils.showSnack(
              context,
              message: '文件删除失败',
              backgroundColor: Colors.red,
            );
          }
        },
        child: const Text('删除'),
      ));
    }

    await showMenu(
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
  }
}
