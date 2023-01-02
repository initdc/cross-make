# frozen_string_literal: true

require "libexec"

require_relative "lib/error"
require_relative "lib/deps"
require_relative "lib/dir"

CROSS_MAKE = true
CONFIG = "qemu-x86_64_defconfig"
CONFIGS = {
  "qemu-x86_defconfig" => "i686-linux-gnu-",
  "qemu-x86_64_defconfig" => "",
  "qemu_arm64_defconfig" => "aarch64-linux-gnu-",
  "qemu_arm_defconfig" => "arm-linux-gnueabi-",
  "qemu-riscv64_defconfig" => "riscv64-linux-gnu-"
}.freeze
FILES = "*.map u-boot*"

Libexec.run("mkdir -p #{arg_dirs}")

jammy_apt
uboot_deps
install_cc if CROSS_MAKE

Dir.chdir(BUILD_DIR) do
  clone_cmd = "git clone https://github.com/u-boot/u-boot.git --depth 1"

  Libexec.run(clone_cmd) unless Libexec.code("test -d u-boot").zero?

  Dir.chdir("u-boot") do
    CONFIGS.each do |config, cross|
      Libexec.code("make #{config}", Econfig)
      make_cmd = if cross.empty?
                   "make -j$(nproc)"
                 else
                   "CROSS_COMPILE=#{cross} make -j$(nproc)"
                 end
      result = Libexec.code(make_cmd).zero?
      next unless result

      pre = config.delete_suffix("_defconfig")
      git_rev = Libexec.output("git rev-parse --short HEAD")
      tar_file = "#{pre}_#{git_rev}.tgz"

      target = "../../#{TARGET_DIR}/u-boot/#{git_rev}/#{pre}"
      Libexec.run("mkdir -p #{target}")
      Libexec.code("tar -zcvf #{tar_file} #{FILES}", Etar)
      Libexec.run("mv #{tar_file} ../../#{UPLOAD_DIR}")
      FILES.split(" ").each do |file|
        Libexec.run("mv #{file} #{target}")
      end
    end
  end
end
