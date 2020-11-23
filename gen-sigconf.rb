require "erb"
require "pathname"
require "yaml"

basedir = Pathname(__FILE__).dirname

module MRubySignature
  refine Array do
    def each_cond_pair
      default = false
      id = 1
      each do |name|
        case
        when name
          yield(name, id)
          id += 1
        when default
          raise "invalid multiple nil entries"
        else
          default = true
        end
      end
      yield(nil, 0)
      self
    end
  end

  refine Hash do
    def each_cond_pair
      default = nil
      each_pair do |name, id|
        if name
          yield(name, id)
        else
          default = id
        end
      end
      yield(nil, default)
      self
    end
  end

  CRC32C_MOD_POLYNOMIAL = 0x82f63b78 # normal 0x1edc6f41 for CRC-32C

  refine Integer do
    def to_signature_for(cnt)
      d = self & 0xffffffff
      cnt.times { d = d.crc32c_update_byte }
      "UINT32_C(0x%08x)" % d
    end

    def crc32c_update_byte
      s = self
      p = CRC32C_MOD_POLYNOMIAL
      8.times {
        s = (s[0] == 0) ? (s >> 1) : ((s >> 1) ^ p)
      }
      s
    end
  end

  unless Pathname.method_defined?(:binwrite)
    refine Pathname do
      def binwrite(path, bin)
        write(path, bin, mode: "wb")
      end
    end
  end
end

using MRubySignature

list = YAML.load(<<-"CONFIGURATIONS.YAML")
- MRBSIG_WORDSIZE:
    MRB_INT32: 32
    MRB_INT64: 64
- MRBSIG_BOXING_TYPE:
  - MRB_NAN_BOXING
  - MRB_WORD_BOXING
- MRBSIG_FLOAT_TYPE:
  - MRB_NO_FLOAT
  - MRB_USE_FLOAT32
- MRBSIG_METHOD_CONTAINER:
  - MRB_USE_METHOD_T_STRUCT
- MRBSIG_ENDIAN:
  - MRB_ENDIAN_BIG
- MRBSIG_DEBUG_HOOK:
  - MRB_USE_DEBUG_HOOK
- MRBSIG_ALL_SYMBOLS:
  - MRB_USE_ALL_SYMBOLS
- MRBSIG_METHOD_CACHE:
  - MRB_NO_METHOD_CACHE
- MRBSIG_DECODE_OPTION:
  - MRB_BYTECODE_DECODE_OPTION
- MRBSIG_GC_FIXED_ARENA:
  - MRB_GC_FIXED_ARENA
- MRBSIG_FIXED_ATEXIT:
  - MRB_FIXED_STATE_ATEXIT_STACK
- MRBSIG_CXX_HANDLING:
  - MRB_USE_CXX_ABI
  - MRB_USE_CXX_EXCEPTION
CONFIGURATIONS.YAML

destpath = basedir + "include/mruby-signature/config.h"
destpath.dirname.mkpath
destpath.binwrite(ERB.new(<<"MRUBY-SIGNATURE/CONFIG.H", trim_mode: "%").result(binding))
/*
 * This file is automatically generated by `ruby gen-sigconf.rb`.
 * All direct changes to this file will be lost.
 */

#ifndef MRUBY_SIGNATURE_CONFIG_H
#define MRUBY_SIGNATURE_CONFIG_H 1

#include <mruby.h> /* for mrbconf.h */
#include <mruby/version.h>
#include <stdint.h>

#if MRUBY_RELEASE_NO < 20000
# if !defined(MRB_INT16) && !defined(MRB_INT32) && !defined(MRB_INT64)
#  define MRB_INT32 1
# endif
#endif

#if MRUBY_RELEASE_NO < 30000
# if defined(MRB_WITHOUT_FLOAT)
#  define MRB_NO_FLOAT 1
# endif

# if defined(MRB_USE_FLOAT)
#  define MRB_USE_FLOAT32 1
# endif

# if defined(MRB_METHOD_CACHE)
#  undef MRB_NO_METHOD_CACHE
# else
#  define MRB_NO_METHOD_CACHE 1
# endif

# if defined(MRB_METHOD_T_STRUCT)
#  define MRB_USE_METHOD_T_STRUCT 1
# endif

# if defined(MRB_ENABLE_DEBUG_HOOK)
#  define MRB_USE_DEBUG_HOOK 1
# endif

# if defined(MRB_ENABLE_ALL_SYMBOLS)
#  define MRB_USE_ALL_SYMBOLS 1
# endif

# if defined(MRB_ENABLE_CXX_ABI)
#  define MRB_USE_CXX_ABI 1
# elif defined(MRB_ENABLE_CXX_EXCEPTION)
#  define MRB_USE_CXX_EXCEPTION 1
# endif
#endif /* MRUBY_RELEASE_NO < 30000 */
% shift = 0
% elements = []
% list.each_with_index do |set|
%   set.each_pair do |key, items|
%     shift += 1
%     elements << key
%     first = true
%     items.each_cond_pair do |name, id|
%       if first
%         raise "wrong empty name" unless name
%         raise "wrong empty id" unless id
%         first = false

#if defined(<%= name %>)
# define <%= key %> <%= id.to_signature_for(shift) %>
%       else
%         if name
#elif defined(<%= name %>)
%         else
#else
%         end
%         if id
# define <%= key %> <%= id.to_signature_for(shift) %>
%         else
# error "wrong conditional"
%         end
%       end
%     end
%   end
#endif
% end

#define MRBSIG_INITIAL  <%= -1.to_signature_for(shift) %>
#define MRBSIG_XOROUT   UINT32_C(0xffffffff)

#define MRUBY_SIGNATURE (MRBSIG_INITIAL ^ \\
% elements.each do |e|
                         <%= e %> ^ \\
% end
                         MRBSIG_XOROUT)

int mruby_signature_check_internal(mrb_state *mrb, uint32_t ver, uint32_t sig);

#endif /* MRUBY_SIGNATURE_CONFIG_H */
MRUBY-SIGNATURE/CONFIG.H
