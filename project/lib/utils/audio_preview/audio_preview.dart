import 'dart:typed_data';

import 'audio_preview_stub.dart'
    if (dart.library.js_interop) 'audio_preview_web.dart'
    as loader;

void playAudioPreview(Uint8List? wavBytes) {
  if (wavBytes == null || wavBytes.isEmpty) return;
  loader.playAudioPreviewImpl(wavBytes);
}
