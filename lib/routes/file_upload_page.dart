import 'package:desktop_drop/desktop_drop.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:remote_files/data/file_upload_task.dart';
import 'package:remote_files/theme/app_theme.dart';
import 'package:remote_files/widgets/loading_btn.dart';

FileUploadTask? currentFileUploadTask;

class FileUploadPage extends StatefulWidget {
  static String get routeName => 'file_upload_page';

  const FileUploadPage({super.key});

  @override
  State<FileUploadPage> createState() => _FileUploadPageState();
}

class _FileUploadPageState extends State<FileUploadPage> {
  String uploadDesc = '';
  double uploadProcess = 0;
  Exception? exception;

  void _setUploadTaskCallback(FileUploadTask fileUploadTask) {
    uploadProcess = fileUploadTask.progress;
    fileUploadTask.onUploadProgress = (int index, int total) {
      if (mounted) {
        uploadDesc = '$index/$total';
      }
    };

    int lastTm = DateTime.now().millisecondsSinceEpoch;
    fileUploadTask.onUploadProgress = (int sent, int total) {
      int currentTm = DateTime.now().millisecondsSinceEpoch;
      // 避免回调过于频繁, 100ms 回调一次
      if (sent == total || currentTm - lastTm > 100) {
        lastTm = currentTm;
        if (mounted) {
          setState(() {
            uploadProcess = fileUploadTask.progress;
          });
        }
      }
    };
    fileUploadTask.onCancel = () {
      if (mounted) {
        currentFileUploadTask = null;
      }
    };
    fileUploadTask.onFailed = (e) {
      if (mounted) {
        exception = e;
        currentFileUploadTask = null;
      }
    };
    fileUploadTask.onDone = () {
      if (mounted) {
        currentFileUploadTask = null;
      }
    };
  }

  @override
  void initState() {
    if (currentFileUploadTask != null) {
      _setUploadTaskCallback(currentFileUploadTask!);
    }
    super.initState();
  }

  @override
  void dispose() {
    currentFileUploadTask?.onNextFileUpload = null;
    currentFileUploadTask?.onUploadProgress = null;
    currentFileUploadTask?.onCancel = null;
    currentFileUploadTask?.onDone = null;
    currentFileUploadTask?.onFailed = null;
    super.dispose();
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
          '文件上传',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
      body: fileUploadBody(),
    );
  }

  Widget fileUploadBody() {
    return Container(
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 36),
          Visibility(
            visible: currentFileUploadTask == null,
            child: DropTarget(
              onDragEntered: (details) {},
              onDragExited: (details) {},
              onDragDone: (details) async {
                List<String> paths = details.files.map((file) => file.path).toList(growable: false);
                if (paths.isEmpty) {
                  return;
                }
                // TODO 选中文件夹的场景, 改成从文件目录页启动文件上传页, 并传入文件目录页路径
                currentFileUploadTask = FileUploadTask.build(filePaths:paths);
                currentFileUploadTask?.startUpload();
                _setUploadTaskCallback(currentFileUploadTask!);
                setState(() {
                  exception = null;
                });
              },
              child: DottedBorder(
                color: Colors.grey,
                strokeWidth: 2,
                dashPattern: const [6, 3],
                child: GestureDetector(
                  onTap: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles();
                    if (result != null) {
                      List<String?> selectPaths =
                      result.files.map((file) => file.path).toList(growable: false);
                      List<String> paths = [];
                      for (var path in selectPaths) {
                        if (path != null) {
                          paths.add(path);
                        }
                      }
                      if (paths.isEmpty) {
                        return;
                      }
                      // TODO 选中文件夹的场景, 改成从文件目录页启动文件上传页, 并传入文件目录页路径
                      currentFileUploadTask = FileUploadTask.build(filePaths:paths);
                      currentFileUploadTask?.startUpload();
                      _setUploadTaskCallback(currentFileUploadTask!);
                      setState(() {
                        exception = null;
                      });
                    }
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: const SizedBox(
                      width: 400,
                      height: 200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.file_upload, size: 60, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            '拖动文件/点击按钮上传',
                            style: TextStyle(fontSize: 24, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Visibility(
            visible: currentFileUploadTask != null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ProgressLoadingWidget(
                  width: 150,
                  height: 150,
                  progress: uploadProcess,
                  desc: uploadDesc,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LoadingBtn(
                    text: '取消',
                    onTap: () {
                      currentFileUploadTask?.cancel();
                      setState(() {
                        currentFileUploadTask = null;
                      });
                    },
                  ),
                )
              ],
            ),
          ),
          Visibility(
            visible: exception != null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 150,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(),
                  child: Text(
                    exception?.toString() ?? 'unknown error',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class ProgressLoadingWidget extends StatelessWidget {
  final double width;
  final double height;
  final double progress;
  final String desc;

  const ProgressLoadingWidget({
    super.key,
    required this.width,
    required this.height,
    required this.progress,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: width,
          height: height,
          child: CircularProgressIndicator(
            value: progress,
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(
          children: [
            Text('${(progress * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 4),
            Text(desc),
          ],
        ),
      ],
    );
  }
}
