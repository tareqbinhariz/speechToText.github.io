import 'dart:async';
import 'dart:typed_data';
import 'package:record/record.dart';

/// Cross-platform audio recorder that captures raw PCM16 audio via
/// [AudioRecorder.startStream] and wraps it in WAV container.
class AudioCapture {
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _subscription;
  final List<Uint8List> _chunks = [];
  InputDevice? _selectedDevice;
  static const int _sampleRate = 44100;
  static const int _numChannels = 1;
  static const int _bitsPerSample = 16;

  Future<bool> hasPermission() async {
    final r = AudioRecorder();
    final ok = await r.hasPermission();
    await r.dispose();
    return ok;
  }

  Future<List<InputDevice>> listDevices() async {
    final r = AudioRecorder();
    final devices = await r.listInputDevices();
    await r.dispose();
    final seen = <String>{};
    final unique = <InputDevice>[];
    for (final d in devices) {
      if (seen.add(d.id)) unique.add(d);
    }
    return unique;
  }

  void selectDevice(InputDevice? device) {
    _selectedDevice = device;
  }

  Future<void> start() async {
    _chunks.clear();
    final r = AudioRecorder();
    final stream = await r.startStream(RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      numChannels: _numChannels,
      sampleRate: _sampleRate,
      device: _selectedDevice,
    ));
    _subscription = stream.listen((data) => _chunks.add(data));
    _recorder = r;
  }

  Future<Uint8List> stop() async {
    if (_recorder == null) throw StateError('Not recording');
    await _recorder!.stop();
    await _subscription?.cancel();
    _subscription = null;
    await _recorder!.dispose();
    _recorder = null;

    final dataSize = _chunks.fold(0, (int s, Uint8List c) => s + c.length);
    final allBytes = Uint8List(dataSize);
    int offset = 0;
    for (final chunk in _chunks) {
      allBytes.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    _chunks.clear();

    return _wrapWav(allBytes);
  }

  void dispose() {
    _subscription?.cancel();
    _recorder?.dispose();
    _recorder = null;
    _chunks.clear();
  }

  static Uint8List _wrapWav(Uint8List pcmData) {
    final dataSize = pcmData.length;
    final fileSize = 36 + dataSize;
    final result = Uint8List(44 + dataSize);
    final b = ByteData.view(result.buffer);

    b.setUint8(0, 0x52); b.setUint8(1, 0x49);
    b.setUint8(2, 0x46); b.setUint8(3, 0x46);
    b.setUint32(4, fileSize, Endian.little);

    b.setUint8(8, 0x57);  b.setUint8(9, 0x41);
    b.setUint8(10, 0x56); b.setUint8(11, 0x45);

    b.setUint8(12, 0x66); b.setUint8(13, 0x6D);
    b.setUint8(14, 0x74); b.setUint8(15, 0x20);
    b.setUint32(16, 16, Endian.little);
    b.setUint16(20, 1, Endian.little);
    b.setUint16(22, _numChannels, Endian.little);
    b.setUint32(24, _sampleRate, Endian.little);
    b.setUint32(28, _sampleRate * _numChannels * _bitsPerSample ~/ 8, Endian.little);
    b.setUint16(32, _numChannels * _bitsPerSample ~/ 8, Endian.little);
    b.setUint16(34, _bitsPerSample, Endian.little);

    b.setUint8(36, 0x64); b.setUint8(37, 0x61);
    b.setUint8(38, 0x74); b.setUint8(39, 0x61);
    b.setUint32(40, dataSize, Endian.little);

    result.setRange(44, 44 + dataSize, pcmData);
    return result;
  }
}
