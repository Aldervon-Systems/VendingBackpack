// Cross-platform storage API. This file conditionally imports the correct
// implementation for web vs IO.

export 'app_storage_io.dart' if (dart.library.html) 'app_storage_web.dart';
