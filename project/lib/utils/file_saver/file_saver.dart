import 'file_saver_stub.dart'
    if (dart.library.js_interop) 'file_saver_web.dart'
    as loader;

/// Triggers a text file download in the browser when running on web.
/// Performs a safe no-op when running on mobile/desktop platforms.
void saveTextFileWeb(String text, String filename) {
  loader.downloadTextFileWeb(text, filename);
}
