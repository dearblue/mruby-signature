#include <mruby-signature.h>
#include <mruby/string.h>
#include <mruby/version.h>

#ifndef mrb_exc_get /* MRUBY_RELEASE_NO < 10300 */
# define mrb_exc_get(M, C) mrb_class_get(M, C)
#endif

#ifndef E_EXCEPTION
# define E_EXCEPTION mrb_exc_get(mrb, "Exception")
#endif

typedef int error_f(mrb_state *mrb, int err, const char *str);

static error_f signature_raise;
static error_f signature_error;

static int
signature_raise(mrb_state *mrb, int err, const char *str)
{
  switch (err) {
  case MRUBY_SIGNATURE_OK:
    break;
  case MRUBY_SIGNATURE_VERSION_MISMATCH:
  case MRUBY_SIGNATURE_MISMATCH:
    mrb_raise(mrb, E_EXCEPTION, str);
  default:
    mrb_raise(mrb, E_EXCEPTION, "[BUG] mruby signature bug [BUG]");
  }

  return MRUBY_SIGNATURE_OK;
}

static int
signature_error(mrb_state *mrb, int err, const char *str)
{
  return err;
}

int
mruby_signature_check_internal(mrb_state *mrb, uint32_t ver, uint32_t sig)
{
  if (mrb == NULL) {
    return MRUBY_SIGNATURE_UNINITIALIZED;
  }

  error_f *err = (mrb->jmp ? signature_raise : signature_error);

  if (ver != MRUBY_RELEASE_NO) {
    return err(mrb,
               MRUBY_SIGNATURE_VERSION_MISMATCH,
               "mruby version mismatch");
  }

  if (sig != MRUBY_SIGNATURE) {
    return err(mrb,
               MRUBY_SIGNATURE_MISMATCH,
               "mruby configuration signature mismatch");
  }

  return MRUBY_SIGNATURE_OK;
}

#define HEXDIG_TO_CHAR(N) (((N) < 10 ? '0' : 'a' - 10) + (N))

void
mrb_mruby_signature_gem_init(mrb_state *mrb)
{
  static const char sig[] = {
    HEXDIG_TO_CHAR((MRUBY_SIGNATURE >> 28) & 0x0f),
    HEXDIG_TO_CHAR((MRUBY_SIGNATURE >> 24) & 0x0f),
    HEXDIG_TO_CHAR((MRUBY_SIGNATURE >> 20) & 0x0f),
    HEXDIG_TO_CHAR((MRUBY_SIGNATURE >> 16) & 0x0f),
    HEXDIG_TO_CHAR((MRUBY_SIGNATURE >> 12) & 0x0f),
    HEXDIG_TO_CHAR((MRUBY_SIGNATURE >>  8) & 0x0f),
    HEXDIG_TO_CHAR((MRUBY_SIGNATURE >>  4) & 0x0f),
    HEXDIG_TO_CHAR((MRUBY_SIGNATURE >>  0) & 0x0f),
    '\0'
  };

  mrb_intern_lit(mrb, "MRUBY_SIGNATURE");
  mrb_define_const(mrb, mrb->object_class, "MRUBY_SIGNATURE", mrb_str_new_static(mrb, sig, sizeof(sig) - 1));
}

void
mrb_mruby_signature_gem_final(mrb_state *mrb)
{
  (void)mrb;
}
