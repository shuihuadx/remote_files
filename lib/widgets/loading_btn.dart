import 'dart:async';

import 'package:flutter/material.dart';

enum BtnStatus {
  normal,
  tapDown,
  loading,
  disable,
}

typedef TapCallback = FutureOr<void> Function();

class LoadingBtn extends StatefulWidget {
  final Color color;
  final String? text;
  final double? textFontSize;
  final String? loadingText;
  final BorderRadiusGeometry? borderRadius;
  final TapCallback? onTap;
  final BtnStatus btnStatus;

  const LoadingBtn({
    Key? key,
    required this.color,
    this.text,
    this.textFontSize = 18,
    this.loadingText,
    this.borderRadius,
    this.onTap,
    this.btnStatus = BtnStatus.normal,
  }) : super(key: key);

  @override
  _LoadingBtnState createState() => _LoadingBtnState();
}

class _LoadingBtnState extends State<LoadingBtn> {
  BtnStatus _btnStatus = BtnStatus.normal;

  @override
  void initState() {
    _btnStatus = widget.btnStatus;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String? text = _btnStatus == BtnStatus.loading
        ? ((widget.loadingText?.isEmpty ?? true) ? widget.text : widget.loadingText)
        : widget.text;
    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        if (_btnStatus == BtnStatus.normal) {
          _btnStatus = BtnStatus.tapDown;
          setState(() {});
        }
      },
      onTapCancel: () {
        if (_btnStatus == BtnStatus.tapDown) {
          _btnStatus = BtnStatus.normal;
          setState(() {});
        }
      },
      onTapUp: (TapUpDetails details) async {
        if (_btnStatus == BtnStatus.tapDown) {
          _btnStatus = BtnStatus.loading;
          setState(() {});

          TapCallback? onTap = widget.onTap;
          if (onTap != null) {
            await onTap();
          }

          _btnStatus = BtnStatus.normal;
          if (mounted) {
            setState(() {});
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _btnStatus == BtnStatus.loading
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
                color: _btnStatus == BtnStatus.normal || _btnStatus == BtnStatus.loading
                    ? Colors.white
                    : const Color.fromARGB(102, 255, 255, 255),
                fontSize: widget.textFontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
