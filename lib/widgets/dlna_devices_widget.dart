import 'package:dlna_dart/dlna.dart';
import 'package:flutter/material.dart';
import 'package:remote_files/utils/dlna_utils.dart';

class DlnaDevicesWidget extends StatefulWidget {
  final Function(DLNADevice device)? onDeviceSelected;

  const DlnaDevicesWidget({
    super.key,
    this.onDeviceSelected,
  });

  @override
  State<DlnaDevicesWidget> createState() => _DlnaDevicesWidgetState();
}

class _DlnaDevicesWidgetState extends State<DlnaDevicesWidget> {
  Map<String, DLNADevice> deviceList = DlnaUtils.deviceList;

  @override
  void initState() {
    super.initState();
    DlnaUtils.deviceListUpdateListener = () {
      if (mounted) {
        setState(() {
          deviceList = DlnaUtils.deviceList;
        });
      }
    };
  }
  @override
  void dispose() {
    DlnaUtils.deviceListUpdateListener = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            deviceList.isEmpty ? '寻找设备中...' : '请选择播放设备',
            style: const TextStyle(
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (final device in deviceList.entries)
          ListTile(
            title: Text(device.value.info.friendlyName),
            subtitle: Text(device.key),
            onTap: () async {
              widget.onDeviceSelected?.call(device.value);
            },
          ),
        deviceList.isEmpty
            ? const Center(
                child: SizedBox(
                  height: 50,
                  width: 50,
                  child: CircularProgressIndicator(),
                ),
              )
            : const SizedBox()
      ],
    );
  }
}
