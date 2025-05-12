class DidcommMessage {
  DidcommMessage();

  String get mediaType => 'application/didcomm-plain+json';

  final Map<String, dynamic> _customHeaders = {};

  dynamic operator [](String key) => _customHeaders[key];
  void operator []=(String key, dynamic value) => _customHeaders[key] = value;
}
