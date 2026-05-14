import 'dart:async';

class BluetoothService {
  final StreamController<String> _controller =
  StreamController<String>.broadcast();

  String _buffer = "";

  Stream<String> get codeStream => _controller.stream;

  void onDataReceived(String rawData) {
    _buffer += rawData;

    // HC-05 غالبًا يرسل \n أو #
    if (_buffer.contains('\n') || _buffer.contains('#')) {
      final parts = _buffer.split(RegExp(r'[\n#]'));

      for (int i = 0; i < parts.length - 1; i++) {
        final code = parts[i].trim();
        if (code.isNotEmpty) {
          _controller.add(code);
          print("📥 Glove code received: $code");
        }
      }

      _buffer = parts.last;
    }
  }

  void dispose() {
    _controller.close();
  }
}
