name: Build APK Release & Web

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'
          cache: 'gradle'

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.3'
          channel: 'stable'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Generate Drift files
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Build APK
        run: flutter build apk --release --no-shrink

      - name: Build Web Preview
        run: flutter build web --release --base-href /putrasurabaya/

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: ud-putra-apk
          path: build/app/outputs/flutter-apk/app-release.apk

      - name: Upload Web
        uses: actions/upload-artifact@v4
        with:
          name: ud-putra-web
          path: build/web

      - name: Deploy to GitHub Pages
        if: success()
        uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./build/web
##
