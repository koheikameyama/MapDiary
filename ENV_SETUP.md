# 環境変数のセットアップ

## 初期セットアップ

### 1. Android用の環境変数

1. `android/local.properties.example`をコピーして`local.properties`を作成：
```bash
cp android/local.properties.example android/local.properties
```

2. `android/local.properties`にGoogle Maps API Key（Android用）を設定：
```properties
GOOGLE_MAPS_API_KEY=YOUR_ANDROID_API_KEY_HERE
```

### 2. iOS用の環境変数

1. `ios/Flutter/Secrets.xcconfig.example`をコピーして`Secrets.xcconfig`を作成：
```bash
cp ios/Flutter/Secrets.xcconfig.example ios/Flutter/Secrets.xcconfig
```

2. `ios/Flutter/Secrets.xcconfig`にGoogle Maps API Key（iOS用）を設定：
```
GOOGLE_MAPS_API_KEY = YOUR_IOS_API_KEY_HERE
```

### 3. その他の環境変数（オプション）

`.env`ファイルを使用する場合（flutter_dotenvを使う場合）：
```bash
cp .env.example .env
# .envファイルを編集
```

## 環境変数の使い方

### 方法1: flutter_dotenv を使用（推奨）

1. パッケージを追加：
```yaml
# pubspec.yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

2. assets を追加：
```yaml
# pubspec.yaml
flutter:
  assets:
    - .env
```

3. main.dart で初期化：
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}
```

4. 使用方法：
```dart
String? apiKey = dotenv.env['GOOGLE_MAPS_API_KEY_ANDROID'];
```

### 方法2: --dart-define を使用

ビルド時に環境変数を指定：

```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=your_key_here
```

コードで使用：
```dart
const apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
```

## セキュリティ注意事項

- ✅ `.env`ファイルは`.gitignore`に追加済み
- ✅ `.env.example`のみGitにコミット（実際の値は含めない）
- ❌ APIキーやシークレットを直接コードに書かない
- ❌ `.env`ファイルをGitにコミットしない

### Google Maps APIキーの設定

**重要:** APIキーに制限を設けない場合、以下のリスクがあります：
- キーが流出した場合、誰でも使用可能
- 予期しない高額請求の可能性
- 第三者による悪用

**推奨する対策：**
1. Google Cloud Consoleで使用量の上限を設定
2. 定期的に使用状況をモニタリング
3. 本番環境では必ずアプリケーション制限を設定

## 設定の確認

環境変数が正しく設定されているか確認：

```bash
# Android
cat android/local.properties | grep GOOGLE_MAPS_API_KEY

# iOS
cat ios/Flutter/Secrets.xcconfig | grep GOOGLE_MAPS_API_KEY
```

## チーム開発時

1. 新メンバーは各`.example`ファイルをコピー：
   - `android/local.properties.example` → `android/local.properties`
   - `ios/Flutter/Secrets.xcconfig.example` → `ios/Flutter/Secrets.xcconfig`
2. 必要なAPIキーを管理者から取得して設定
3. パスワード管理ツール（1Password, LastPassなど）で共有を推奨

## 重要な注意事項

以下のファイルは`.gitignore`に追加済みで、Gitにコミットされません：
- ✅ `android/local.properties`
- ✅ `ios/Flutter/Secrets.xcconfig`
- ✅ `.env`（使用する場合）

間違ってコミットしないよう注意してください！
