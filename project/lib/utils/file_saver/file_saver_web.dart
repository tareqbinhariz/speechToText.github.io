import 'dart:convert';
import 'dart:js_interop';

@JS('eval')
external void _eval(JSString code);

void downloadTextFileWeb(String text, String filename) {
  final jsCode = """
    const element = document.createElement('a');
    element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(${jsonEncode(text)}));
    element.setAttribute('download', '${filename.replaceAll("'", "\\'")}');
    element.style.display = 'none';
    document.body.appendChild(element);
    element.click();
    document.body.removeChild(element);
  """;
  _eval(jsCode.toJS);
}
