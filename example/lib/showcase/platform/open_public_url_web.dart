import 'package:web/web.dart' as web;

void openPublicUrl(String url) {
  web.window.location.assign(url);
}
