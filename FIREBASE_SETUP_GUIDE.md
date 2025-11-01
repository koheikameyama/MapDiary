# Firebase セットアップガイド（Android）

このガイドでは、SnapMapアプリのAndroid版でFirebaseを設定する手順を説明します。

## ステップ1: Firebaseプロジェクトを作成

1. **Firebase Consoleにアクセス**
   - [https://console.firebase.google.com/](https://console.firebase.google.com/)にアクセス
   - Googleアカウントでログイン

2. **新しいプロジェクトを作成**
   - 「プロジェクトを追加」をクリック
   - プロジェクト名: `SnapMap`（または任意の名前）
   - Google Analyticsは「今は不要」を選択（後で追加可能）
   - 「プロジェクトを作成」をクリック

## ステップ2: Firebase Authentication を有効化

1. Firebase Consoleで作成したプロジェクトを開く
2. 左メニューから「構築」→「Authentication」を選択
3. 「始める」をクリック
4. 「Sign-in method」タブを選択
5. 「メール/パスワード」を選択して有効化
6. 「保存」をクリック

## ステップ3: Cloud Firestore を作成

1. 左メニューから「構築」→「Firestore Database」を選択
2. 「データベースの作成」をクリック
3. ロケーションを選択（例: asia-northeast1 (Tokyo)）
4. **テストモードで開始**を選択（開発中のみ）
5. 「作成」をクリック

### セキュリティルールの設定（後で本番モードに変更）

「ルール」タブで以下のルールを設定：

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    match /posts/{postId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
      allow delete: if request.auth != null && request.auth.uid == resource.data.userId;
    }

    match /reports/{reportId} {
      allow read: if false;
      allow create: if request.auth != null;
    }
  }
}
```

## ステップ4: Firebase Storage を有効化

1. 左メニューから「構築」→「Storage」を選択
2. 「始める」をクリック
3. セキュリティルールは「本番モードで開始」を選択
4. ロケーションを選択（Firestoreと同じ場所を推奨）
5. 「完了」をクリック

### セキュリティルールの設定

「ルール」タブで以下のルールを設定：

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /posts/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
                   && request.resource.size < 5 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*');
    }
  }
}
```

## ステップ5: Androidアプリを追加

1. Firebase Consoleのプロジェクト概要ページで「Androidアイコン」をクリック
2. Androidパッケージ名: `com.snapmap.snap_map`
3. アプリのニックネーム: `SnapMap Android`（任意）
4. デバッグ用の署名証明書 SHA-1: スキップ可能（Google Maps使用時は設定推奨）
5. 「アプリを登録」をクリック
6. `google-services.json`ファイルをダウンロード

### google-services.jsonを配置

ダウンロードした`google-services.json`を以下の場所に配置：
```
android/app/google-services.json
```

## ステップ6: FlutterFireの設定

ターミナルでプロジェクトのルートディレクトリに移動し、以下を実行：

```bash
# FlutterFire CLIで自動設定
flutterfire configure
```

プロンプトに従って：
1. 作成したFirebaseプロジェクト「SnapMap」を選択
2. プラットフォームで「android」を選択
3. 自動的に`firebase_options.dart`が生成されます

## ステップ7: Google Maps APIキーの取得と設定

### Google Cloud Consoleでの設定

1. [Google Cloud Console](https://console.cloud.google.com/)にアクセス
2. Firebase プロジェクトと同じプロジェクトを選択
3. 「APIとサービス」→「ライブラリ」を選択
4. 「Maps SDK for Android」を検索して有効化
5. 「APIとサービス」→「認証情報」を選択
6. 「認証情報を作成」→「APIキー」をクリック
7. 作成されたAPIキーをコピー

### APIキーの制限設定（推奨）

1. 作成したAPIキーの名前をクリック
2. 「アプリケーションの制限」で「Androidアプリ」を選択
3. 「項目を追加」をクリック
4. パッケージ名: `com.snapmap.snap_map`
5. SHA-1証明書のフィンゲープリントを追加（デバッグキー）

#### デバッグSHA-1の取得方法（Mac/Linux）

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

6. 「API の制限」で「キーを制限」を選択
7. 「Maps SDK for Android」にチェック
8. 「保存」をクリック

### AndroidManifest.xmlにAPIキーを設定

`android/app/src/main/AndroidManifest.xml`を開き、`YOUR_GOOGLE_MAPS_API_KEY_HERE`を取得したAPIキーに置き換え：

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ACTUAL_API_KEY_HERE"/>
```

## ステップ8: main.dartのFirebase初期化を有効化

`lib/main.dart`を開き、以下のコメントアウトを解除：

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // この部分のコメントを外す
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}
```

## ステップ9: ビルドと実行

```bash
# 依存関係を取得
flutter pub get

# Androidデバイス/エミュレータで実行
flutter run
```

## トラブルシューティング

### google-services.jsonが見つからない

エラー: `File google-services.json is missing`

**解決方法:**
- `google-services.json`が`android/app/`ディレクトリに配置されているか確認
- Firebase Consoleから再ダウンロード

### Google Mapsが表示されない

**解決方法:**
- APIキーが正しく設定されているか確認
- Maps SDK for Androidが有効化されているか確認
- APIキーの制限設定を一時的に「なし」にして動作確認

### MultiDex エラー

エラー: `Cannot fit requested classes in a single dex file`

**解決方法:**
- すでに`build.gradle`で`multiDexEnabled true`が設定されています
- クリーンビルドを実行: `flutter clean && flutter pub get`

### 位置情報が取得できない

**解決方法:**
- 実機で動作確認（エミュレータでは位置情報が不正確）
- アプリ起動時に位置情報の権限を許可
- 設定→アプリ→SnapMap→権限で位置情報が許可されているか確認

## 次のステップ

1. アプリを起動
2. アカウントを作成してログイン
3. 写真を投稿して動作確認
4. 地図上で投稿を確認

セットアップが完了したら、実際に使ってみてください！
