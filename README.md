# mruby-signature - generate build configuration signature

mruby のバージョンとビルド設定に依存する、一意の署名を生成します。

例えば、`MRB_WORD_BOXING` が定義された mruby と `MRB_NAN_BOXING` が定義された mruby に対するビルド署名は異なります。
署名が影響を受けるのは、C の型や構造体を変更する設定マクロの有無です。

mruby-signature の主な目的は、mruby 本体に付属している "mrbgems/mruby-bin-config" を補完することです。
例えば共有ライブラリ (so ファイルや dll ファイルなど) を用いて mruby の本体が分かれている場合に、バイナリ互換性 (ABI 互換) があるかどうかを動作時に確認することが出来ます。


## API

### C API

  - `MRUBY_SIGNATURE` マクロ定数 (`include/mruby-signature.h`)
  - `mruby_signature_check()` マクロ関数 (`include/mruby-signature.h`)

### Ruby API

  - `MRUBY_SIGNATURE` 定数: 署名としての文字列を返します。


## くみこみかた

`build_config.rb` に gem として追加して、mruby をビルドして下さい。

```ruby
MRuby::Build.new do |conf|
  conf.gem "mruby-signature", github: "dearblue/mruby-signature"
end
```

- - - -

mruby gem パッケージとして依存したい場合、`mrbgem.rake` に記述して下さい。

***[注意]***: mruby-signature は mruby 本体と同じバイナリ単位でビルドされなければうまく機能しません。

```ruby
# mrbgem.rake
MRuby::Gem::Specification.new("mruby-XXX") do |spec|
  ...
  spec.add_dependency "mruby-signature", github: "dearblue/mruby-signature"
end
```


## つかいかた

### 分割してあるライブラリファイルと動的リンクするような場合

動的にリンクされたライブラリ側の mruby ライブラリ初期化関数 (`mrb_mruby_XXX_gem_init()` のような関数) で `mruby_signature_check(mrb)` するだけです。
他の mruby API を操作する前に実行するべきです。

```c
#include <mruby-signature.h>

void
mrb_mruby_XXX_gem_init(mrb_state *mrb)
{
  /* ビルド設定に齟齬がある場合は例外が発生します。 */
  mruby_signature_check(mrb);

  ...
}
```

### 書き捨て `main()` 関数とリンクして使いたい

`build_config.rb` に記述された設定値は、ビルド単位を分けた場合には反映されません。
そのため、直接コンパイル・リンクまで行う場合、`build_config.rb` の設定と齟齬があるならば、エラーを確認出来ないままクラッシュするでしょう。

`mrb_open()` 関数 (あるいは `mrb_open_alloc()`、`mrb_open_core()`) の直後に `mruby_signature_check(mrb)` を行うことで、この問題に対処することが出来ます。

```c
#include <mruby.h>
#include <mruby-signature.h>

int main(void)
{
  mrb_state *mrb = mrb_open();
  int err = mruby_signature_check(mrb);

  if (err == MRUBY_SIGNATURE_OK) {
    printf("OK!\n");
  } else {
    printf("Mismatch configuration!\n");
  }

  if (err >= MRUBY_SIGNATURE_OK) {
    mrb_close(mrb);
  }

  return 0;
}
```

```console
% cc -I include -I build/repos/host/mruby-signature/include example1.c -L build/host/lib -lmruby -lm
% ./a.out
OK!
% cc -DMRB_NAN_BOXING -I include -I build/repos/host/mruby-signature/include example1.c -L build/host/lib -lmruby -lm
% ./a.out
Mismatch configuration!
```


### mruby 空間で署名を確認したい

mruby 空間で16進数による署名を確認することが出来ます。

```ruby
p MRUBY_SIGNATURE # => "fedcba98"
```


## Specification

  - Package name: mruby-signature
  - Version: 0.1
  - Product quality: PROTOTYPE
  - Author: [dearblue](https://github.com/dearblue)
  - Project page: <https://github.com/dearblue/mruby-signature>
  - Licensing: [Creative Commons Zero License (CC0)](LICENSE) (likely Public Domain)
  - Object code size: under 1 KiB
  - Required runtime heap size: under 1 KiB
  - Dependency external mrbgems: (NONE)
  - Bundled C libraries (git-submodules): (NONE)
