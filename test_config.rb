#!ruby

require "yaml"
begin
  require "mruby/source"
rescue LoadError
  $: << File.expand_path(File.join(MRUBY_ROOT, "lib"))
  require "mruby/source"
end

config = YAML.load <<'test-config.yaml'
  common:
    gems:
    - :core: "mruby-sprintf"
    - :core: "mruby-print"
    - :core: "mruby-bin-mrbc"
    - :core: "mruby-bin-mirb"
    - :core: "mruby-bin-mruby"
  builds:
    host:
      defines: MRB_WORD_BOXING
      gems:
      - :core: "mruby-io"
    host++exc-nanbox:
      defines: MRB_NAN_BOXING
      c++exc: true
      mruby-skip: 10200
    host++abi-nobox:
      defines: MRB_NO_BOXING
      c++abi: true
      mruby-skip: 10200
test-config.yaml

config["builds"].each_pair do |n, c|
  if (skip = c.dig("mruby-skip")) && skip >= MRuby::Source::MRUBY_RELEASE_NO
    next
  end

  MRuby::Build.new(n) do |conf|
    toolchain :clang

    conf.build_dir = File.join("build", c["build_dir"] || name)

    compilers.each { |cc| cc.defines << [*c["defines"]] }
    cc.flags << [*c["cflags"]]

    case
    when c["c++abi"]
      enable_cxx_abi
    when c["c++exc"]
      enable_cxx_exception
    end

    enable_debug unless c["nodebug"]
    enable_test unless c["notest"]

    gem core: "mruby-bin-mruby-config" rescue nil
    gem core: "mruby-bin-config" rescue nil

    Array(config.dig("common", "gems")).each { |*g| gem *g }
    Array(c["gems"]).each { |*g| gem *g rescue nil }

    gem __dir__ do |g|
      if g.cc.command =~ /\b(?:g?cc|clang)\d*\b/
        cc.flags << (c["c++abi"] ? "-std=c++11" : "-std=c99")
        cxx.flags << "-std=c++11"
        compilers.each { |cc| cc.flags <<
          %w(-Werror=all -Werror=extra -Werror=undef -Wpedantic
             -Wno-newline-eof -Wno-unused-parameter
             -Wno-declaration-after-statement)
        }
      end
    end
  end
end
