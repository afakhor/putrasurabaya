import 'native.dart' if (dart.library.html) 'web.dart' as impl;

DatabaseConnection connect() => impl.connect();