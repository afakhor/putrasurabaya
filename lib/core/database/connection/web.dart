import 'package:drift/drift.dart'; // PAKE drift AJA, BUKAN drift/web

DatabaseConnection connect() {
  return DatabaseConnection.delayed(Future.value(
    WebDatabase('ud_putra_web_db'), // WebDatabase udah ada di package drift
  ));
}