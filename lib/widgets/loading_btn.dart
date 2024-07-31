import 'dart:async';

import 'package:flutter/material.dart';

enum BtnStatus {
  normal,
  loading,
  disable,
}

typedef TapCallback = FutureOr<void> Function();

class LoadingBtn extends StatefulWidget {
  final String? text;
  final double? textFontSize;
  final String? loadingText;
  final TapCallback? onTap;
  final BtnStatus btnStatus;
  final FocusNode? focusNode;

  const LoadingBtn({
    Key? key,
    this.text,
    this.textFontSize = 18,
    this.loadingText,
    this.onTap,
    this.btnStatus = BtnStatus.normal,
    this.focusNode,
  }) : super(key: key);

  @override
  State<LoadingBtn> createState() => _LoadingBtnState();
}

class _LoadingBtnState extends State<LoadingBtn> {
  BtnStatus btnStatus = BtnStatus.normal;
  late FocusNode focusNode;
  bool hasFocus = false;

  @override
  void initState() {
    btnStatus = widget.btnStatus;
    focusNode = widget.focusNode ?? FocusNode();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String? text = btnStatus == BtnStatus.loading
        ? ((widget.loadingText?.isEmpty ?? true) ? widget.text : widget.loadingText)
        : widget.text;
    return FilledButton(
      focusNode: focusNode,
      style: ButtonStyle(
        elevation: WidgetStateProperty.all(hasFocus ? 10 : 0),
      ),
      onFocusChange: (value) {
        setState(() {
          hasFocus = value;
        });
      },
      onPressed: () async {
        if (btnStatus == BtnStatus.disable || btnStatus == BtnStatus.loading) {
          return;
        }
        TapCallback? onTap = widget.onTap;
        if (onTap != null) {
          setState(() {
            btnStatus = BtnStatus.loading;
          });
          await onTap();
          if (mounted) {
            setState(() {
              btnStatus = BtnStatus.normal;
            });
          }
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          btnStatus == BtnStatus.loading
              ? Container(
            margin: const EdgeInsets.only(right: 16),
            child: const SizedBox(
              height: 17,
              width: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                backgroundColor: Color.fromARGB(77, 255, 255, 255),
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          )
              : Container(),
          Text(
            text ?? '',
            style: TextStyle(
              color: btnStatus == BtnStatus.normal || btnStatus == BtnStatus.loading
                  ? Colors.white
                  : const Color.fromARGB(102, 255, 255, 255),
              fontSize: widget.textFontSize,
            ),
          ),
        ],
      ),
    );
  }
}
