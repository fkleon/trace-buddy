/** Build logic that lets the Dart editor build the app in the background. */
import 'package:web_ui/component_build.dart';

main() {
  build(['--', '--basedir', '.'], ['web/TraceBuddy.html']);
}