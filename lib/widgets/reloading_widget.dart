import 'package:flutter/material.dart';

/// 出错重试 Widget, FutureBuilder 页面加载失败时, 可使用本控件进行点击失败重试
class ReloadingView extends StatelessWidget {
  final String? errorReason;
  final String? retryButtonText;
  final VoidCallback? onPressed;

  const ReloadingView({
    Key? key,
    this.errorReason,
    this.retryButtonText,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 200,
            ),
            Container(height: 16),
            errorReason?.isEmpty ?? true
                ? const SizedBox()
                : Container(
                    margin: const EdgeInsets.only(top: 10),
                    child: Text(
                      errorReason ?? '',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                    ),
                  ),
            Container(
              margin: const EdgeInsets.only(top: 42, bottom: 42),
              width: 130,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: Theme.of(context).primaryColor,
              ),
              child: TextButton(
                onPressed: onPressed,
                child: Text(
                  retryButtonText ?? '重试',
                  style: const TextStyle(fontSize: 17, color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
