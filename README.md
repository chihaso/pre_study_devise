# README
## 概要
このリポジトリはDeviseによる認証の個人学習用のためのものです。  
サンプルアプリ（書籍情報を記録するアプリ）にDeviseを導入し、アカウント登録やサインインといった機能の追加方法を確認しています。

## DeviseのREADME読書メモ
以下は[DeviseのREADME](https://github.com/heartcombo/devise)を読んで、その記載内容等を自分の理解の範囲で書き出したものです。  
*READMEを忠実に日本語に翻訳したものではありません。意訳や個人的な解釈、疑問点、別の場所に記載されている内容なども含まれています。*

### Deviseは[Warden](https://github.com/wardencommunity/warden)ベース 
- Wardenってどんなもの？(以下[公式wikiのOverview](https://github.com/wardencommunity/warden/wiki/Overview)より)
  - rackベースのミドルウェア
  - 使われなければ何もしない
      - `env['warden']`のメソッド実行しない限り何もしない
  - サプアプリケーションとかも含めてすべて共通のロジックでユーザーにアクセスしたり認証を要求したりできる
  - WardenはRackスタックのsessionミドルウェアの後にいる
  - `env['warden']`にlazy objectを注入する。
      - こいつのメソッド使って認証されてるかどうか確認したり、下流は強制的に認証させたりできる。認証されれば何もしないし、されてなければ失敗させる
      - 認証されれば'user'にアクセスできる `env['warden'].user`
          - 'user'はnilでなければどんなオブジェクトでもいい。
  - sessionミドルウェアの直後にいることで、それより下流のアミドルウェアやプリケーションは全部`env['warden']`にアクセスできるので、同一の認証システムにより一貫した認証が可能
  - 認証失敗させたい時は、`throw(:warden)`すればいい（hashでオプション指定も可）
      - [throwは大域脱出メソッド](https://docs.ruby-lang.org/ja/latest/method/Kernel/m/throw.html)なので、`catch(:warden)`ブロックの終わりにジャンプする（*「Failure Application」に移る?*）
      - 「Failure Application」は標準的なRackアプリケーションであり、例えばログインフォームの描画などに使う。これは自前でセットアップする必要がある。
  - 認証のサイクル中のいろんなキーポイントに対応するcallbackがある
  - Scope機能により、同時に複数のユーザーの認証が可能。

### Deviseは10種のmoduleから構成される
- [Database Authenticatable](https://www.rubydoc.info/github/heartcombo/devise/master/Devise/Models/DatabaseAuthenticatable)
    - ハッシュ化したパスワードをDBに保存してサインイン時に認証を行う。
    - `password=`メソッドが定義されていて、こいつが引数をハッシュ化して`encrypted_password`カラムに入れる
        - 既存の`password`カラムがあればそれを「バイパス」する（*passwordカラムをそのまま使うってことかな？*）
        - 認証にはPOSTリクエストかHTTP Basic認証が使える
- [Omniauthable](https://www.rubydoc.info/github/heartcombo/devise/master/Devise/Models/Omniauthable)
    - モデルをOmuniAuthに対応させる
- [Confirmable](https://www.rubydoc.info/github/heartcombo/devise/master/Devise/Models/Confirmable)
    - アカウントがすでに確認済みかどうかをチェック
    - アカウント作成時、もしくは要求された場合に確認用メールを送信する    
- [Recoverable](https://www.rubydoc.info/github/heartcombo/devise/master/Devise/Models/Recoverable)
    - パスワードのリセットをしたり、そのためのメールを送信する
- [Registerable](https://www.rubydoc.info/github/heartcombo/devise/master/Devise/Models/Registerable)
    - ユーザ登録や編集、削除など、登録に関わる全てを担う
- [Rememberable](https://www.rubydoc.info/github/heartcombo/devise/master/Devise/Models/Rememberable)
    - cookieを利用してユーザーを記憶するためのtokenを生成or削除する
    - ユーザーをcookieにシリアライズしたり、そこから戻したり（*cookie上の情報をもとにユーザーのインスタンスを再生するって意味？*）するためのユーティリティもあるが、これらは主に内部的に使われている
- [Trackable](https://www.rubydoc.info/github/heartcombo/devise/master/Devise/Models/Trackable)
    - サインイン回数とか、タイムスタンプとか、IPアドレスをカラムに保持する（前回のものと、現在のもの）
- [Timeoutable](https://www.rubydoc.info/github/heartcombo/devise/master/Devise/Models/Timeoutable)
    - セッションの有効期限が過ぎているかどうかチェックして、過ぎてたらもう一度認証を要求する（サインインページにリダイレクトする）
- [Validatable](https://www.rubydoc.info/github/heartcombo/devise/master/Devise/Models/Validatable)
    - これを有効にすることで、email と passwordに関するバリデーションがかけられる。
    - emailの存在、一意性、フォーマットと、passwordの存在、確認、長さについては自動的にバリデーションがかけられており、それ以外のバリデーションの追加も可能
    - 内部的には普通にRailsのバリデーションヘルパーを使用している ([source](https://github.com/heartcombo/devise/blob/5d5636f03ac19e8188d99c044d4b5e90124313af/lib/devise/models/validatable.rb#L26-L44))
    - > Validatable adds the following options to devise_for:
        - 上記間違ってる気がする。実際にはroutes.rbの`devise_for`ではなく、モデル内の`devise`に`email_regexp`、`password_length`のオプションを設定できる様になる
        - コントリビュートチャンス？
            - 他のモジュールのコメントにも同様の記載あり（詳細は未確認） 
    - [`Devise::Models.config`](https://github.com/heartcombo/devise/blob/c82e4cf47b02002b2fd7ca31d441cf1043fc634c/lib/devise/models.rb#L31)によりアクセサを追加している
        - 実際にはメソッドを追加している
- [Lockable](https://www.rubydoc.info/github/heartcombo/devise/master/Devise/Models/Lockable) 
    - 所定の回数パスワードを間違えたらロックをかける
    - ロック解除の方法は２通りあり、一つはロック解除用のアドレスをメールで送信する方法、もう一つは所定の時間が経過したらロック解除する方法。両方設定することも可能。


### バグレポートについて
- 手順があるのでwikiを見ること
- セキュリティに関わる問題を報告する場合はissueは立てずにメールで報告する必要がある

### コントリビュートについて
- DeviseはORMとしてActiveRecordのほかMongoidにも対応しているため、テスト時は必要に応じて環境変数`DEVISE_ORM`に使用するORMをセットして確認する必要がある
- 複数のバージョンのRuby、Railsに対応しているので、こちらも必要に応じて環境変数`BUNDLE_GEMFILE`にバージョンを指定して`bundle install`したり、テストする必要がある
  
### Deviseを使い始める前に
- Railsに不慣れな人に向けていくつか教材が用意されている
    - 「Ryan Bates' Railscasts」はスクラッチで認証機能を作成するという内容。わかりやすいがRailsのバージョンが古いのでRails6系とか新しいバージョンではそのままでは動かない
        - [一つ目の動画](http://railscasts.com/episodes/250-authentication-from-scratch)の内容をRails6系で動くようにアレンジして実装してみた。 → https://github.com/chihaso/auth
        - [二つ目の動画](http://railscasts.com/episodes/250-authentication-from-scratch-revised) は、一つ目の動画の内容をブログアプリ上に実装して、さらにブログ編集時の認証機能を追加するというもの

### Devise導入手順
1. deviseをGemfileに追加して`bundle install`
2. `rails generate devise:install`
    - これを実行すると各種設定を行うようにメッセージが表示されるので指示通りに設定を加えていく
        1. config/environments/development.rb に`config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }`を追加
            - メールにホストへのリンクを貼るために必要になる。とりあえずdevelopment環境だけ、localhost:3000にセットしておく
        2. config/routes.rb にrootを設定
        3. app/views/layouts/application.html.erb にflashメッセージを追加しておく
3. Deviseにより生成されるviewは後々カスタマイズしたいので、`rails g devise:views`を実行
    - デフォルトのviewのコピーが作成される
4. generatorにより生成されたinitializerの中身を確認する
    - 設定一覧
    - 暗号キー：ユーザーが自由に変えられるが、これを変えると既存のパスワードやトークンは全て無効になる(多分パスワードのハッシュ化に使われてる) 
    - 親のコントローラー名
    - デフォルトのメール送信元アドレス
    - メール送信を行うクラス
    - ORMの設定
    - 認証に使うキーの指定:デフォルトはemailのみだが、ユーザー名とかも追加できる
    - リクエストオブジェクトのキー（?）
    - 大文字小文字を区別しない認証キー（デフォルト :email 登録時、変更時には小文字にされる）　
    - 空白除去する認証キー（デフォルト :email 登録時、変更時には空白除去される）
    - request.paramsによる認証を可能にするかどうか（？） デフォルトTrue
    - HTTP認証による認証を可能にするかどうか
    - AJAXによるリクエストに401を返すかどうか （HTTP認証の最初のアクセス時の話と思われる）
    - Basic認証のrealm
    - アドレスの正誤に関わらず確認とかパスワード回復とかその他が同じように動作するようにする(?)
    - セッションに保存するのをスキップしたい認証方式
    - ・・・いっぱいあり過ぎてここまでが限界・・・後で読む・・・
5. `rails generate devise 任意のモデル名`実行
6. マイグレーションファイルが生成されるので、デフォルトの設定以外に追加したいモジュールがあれば、該当箇所のコメントを解除
7. railsを起動しているなら再起動する（springも）
    - springが動いてるかどうかは`bin/spring status`
    - 止めるなら`bin/spring stop`
    - springは `rails console`とか`rails test`とか実行するときに使われる（起動する）
8. この時点で登録、ログイン、ログアウト、パスワード変更などのルーティング、アクション、ビューができているので確認
    - 必要に応じてviewにリンクを追加するなどしておく
9. 他の認証したいコントローラーに`before_action :authenticate_「5.で設定したモデル名のdouwncase」!`を追加
    - こいつを記述したコントローラーの指定したアクション(only: とかで指定)を実行するときにログインしていないと、ログイン画面にリダイレクトする

- サインイン後やパスワード更新後のタイミングなどのリダイレクト先は、デフォルトでモデル名_root_pathがあればそこへ、なければroot_pathへリダイレクトする
    - そのため自分でrootを設定しておく必要がある
    - after_sign_in_path_for とかをoverrideすればリダイレクト時のフックをカスタマイズ可能
- モデル内のdeviseメソッドには、各モジュールの他streches: など各種オプションを設定可能（詳細はinitializerを参照）

### strong parameter
- deviseが許可しているパラメータセットは下記3種
    - sign_in: 認証キー（例えばemail）のみを許可(*passwordは？*)
    - sign_up: 認証キーとpasswordとpassword_confirmation
    - account_update: 認証キーとpasswordとpassword_confirmationとcurrent_password
- 許可するパラメータを増やしたい時は、ApplicationControllerに下記のようなbefore actionを追加することで可能
    ```
    class ApplicationController < ActionController::Base
      before_action :configure_permitted_parameters, if: :devise_controller?

      protected

      def configure_permitted_parameters
        devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
      end
    end
    ```
- 下記のようにブロックを渡すことで、デフォルトのパーミッションをカスタマイズすることも可能
    ```
      def configure_permitted_parameters
        devise_parameter_sanitizer.permit(:sign_in) do |user_params|
          user_params.permit(:username, :email)
        end
      end
    ```
- Deviseを使用するモデルが複数ある場合は、Devise::ParameterSanitizerを継承してモデルごとにセッティングするのが良い

### viewのカスタマイズ
- もしもDeviseを使用するモデルが複数ある場合は、config/initializers/devise.rbで`config.scoped_views = true`とする
- スコープごとのviewの生成は`rails generate devise:views users`みたいにすれば可能
    - もしもそのスコープのviewがなければ、deviseはデフォルトのviewを使用する
- モジュールごとのviewを生成したい時は`rails generate devise:views -v registrations confirmations`みたいにする

### controllerのカスタマイズ
- viewのカスタマイズでは不足である場合、下記手順でcontrollerのカスタマイズが可能
    1. `rails generate devise:controllers [scope]`
        - scopeはモデル名の複数形（このnamespaceでディレクトリが生成され、その配下に各種コントローラーがが生成される）
    2. routes.rbで下記の様にして、各controllerを指定する
        ```
        devise_for :users, controllers: {
          sessions: 'users/sessions'
        }
        ```
    3. viewファイルのパスのディレクトリ名がデフォルトだとdeviseになってるので、適宜変更
        - 変えなくても一見正常に表示されるが、「想定されるディレクトリ配下にviewがなければデフォルトのディレクトリ配下のものを使用する」みたいな動作でとりあえず動いているだけかも
        - deviseを使うモデルが増えたら破綻する気がする（まあそのときにはnamespace分けざるを得ないから結局問題ない気もするが・・・）
        4. コントローラーの記載を任意に書き換える

### その他
- routes.rb内では`devise_scope`メソッドを使用することで特定のルーティングを変更することも可能
    - 全て書き換える場合でも`devise_for`は必要
- OmniAuth使いたい場合はinitializer内で設定が必要
- Deviseを使うモデルは複数設定可能。ただしコントローラーを分ける必要がある
    - おなじアクション内でuserのロールによって振る舞いを分けたいとかだったら、roleカラムを追加するとか、専用のgemを使うべき
- ActiveJobを使っているなら、モデル内で`send_devise_notification`をoverrideすることで既存のqueueを使ってdeviseからのメール配信したりもできる
- Recoverable モジュールを有効にしている場合、ログレベルの設定がデフォルトの :info のままだとパスワードリセット用のトークンが平文でリークする恐れがある
    - config/environments/production.rb で　`config.log_level = :warn` とする
    - Railsのログレベルについては https://qiita.com/sobameshi0901/items/b963e7046e2ae8b8e813
- APIモードにもある程度対応しているが、完全ではない
    - APIモードの場合cookieによるデフォルトの認証方式が使えない。Basic認証は使える（別途設定が必要）

## パスワードリセット等のメールを送れる様にするには
- まず、config/environments 配下の各環境の設定で、`config.action_mailer.raise_delivery_errors`をtrueにして、メール配信に失敗したときに例外が発生する様にしておく
- 例えばGmailのアドレスを使う場合は、[Railsガイド](https://railsguides.jp/action_mailer_basics.html#gmail%E7%94%A8%E3%81%AEaction-mailer%E8%A8%AD%E5%AE%9A) にある様に設定を追加するだけでOK
    - ただし、Gmailで2段階認証を有効にしている場合は別途「アプリパスワード」を発行して使用する必要がある（それも含めてガイドに記載あり）


