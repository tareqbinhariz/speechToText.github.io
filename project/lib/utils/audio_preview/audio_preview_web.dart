import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

@JS('eval')
external void _eval(JSString code);

void playAudioPreviewImpl(Uint8List wavBytes) {
  final base64 = base64Encode(wavBytes);
  _eval(
    'new Audio("data:audio/wav;base64,$base64").play()'
    '.catch(function(e){console.error("Playback failed:",e)});'.toJS,
  );
}
