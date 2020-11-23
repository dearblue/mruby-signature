/**
 * @file include/mruby-signature.h
 */

#ifndef MRUBY_SIGNATURE_H
#define MRUBY_SIGNATURE_H 1

#include <mruby.h>
#include <mruby/version.h>
#include "mruby-signature/config.h"

#define MRUBY_SIGNATURE_OK                  0
#define MRUBY_SIGNATURE_UNINITIALIZED       (-1)
#define MRUBY_SIGNATURE_MISMATCH            1
#define MRUBY_SIGNATURE_VERSION_MISMATCH    2

/**
 * `MRB` は `mrb_state *` の型を取ります。
 * `NULL` 安全なので、`mrb_open()` を行った直後に渡すことが出来ます。
 * 戻り値は `int` 型で `MRUBY_SIGNATURE_OK` 以外はエラーであり、それ以上の操作を行うとおそらくプロセスはクラッシュします。
 *
 *      mrb_state *mrb = mrb_open();
 *      int err = mruby_signature_check(mrb);
 *
 *      if (err == MRUBY_SIGNATURE_OK) {
 *          通常の処理
 *      }
 *
 *      if (err >= MRUBY_SIGNATURE_OK) {
 *          mrb_close(mrb);
 *      }
 */
#define mruby_signature_check(MRB) mruby_signature_check_internal(MRB, MRUBY_RELEASE_NO, MRUBY_SIGNATURE)

#endif /* MRUBY_SIGNATURE_H */
