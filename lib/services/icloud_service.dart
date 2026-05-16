import 'package:flutter/services.dart';

class ICloudService {
  static const _channel = MethodChannel('com.printshopapp/icloud');

  static final ICloudService _instance = ICloudService._internal();
  factory ICloudService() => _instance;
  ICloudService._internal();

  bool _isAvailable = false;
  String? _documentsPath;

  bool get isAvailable => _isAvailable;
  String? get documentsPath => _documentsPath;

  Future<void> init() async {
    try {
      final path = await _channel.invokeMethod<String>('getDocumentsPath');
      if (path != null && path.isNotEmpty) {
        _isAvailable = true;
        _documentsPath = path;
      } else {
        _isAvailable = false;
        _documentsPath = null;
      }
    } on MissingPluginException {
      _isAvailable = false;
      _documentsPath = null;
    } catch (e) {
      _isAvailable = false;
      _documentsPath = null;
    }
  }
}
