import 'package:drift/drift.dart';
import 'package:drift/web.dart';

DatabaseConnection connect() {
  return DatabaseConnection.delayed(Future(() async {
    return DatabaseConnection(WebDatabase('ud_putra_web_db'));
  }));
}