# frozen_string_literal: true

require "libexec"

require_relative "lib/error"
require_relative "lib/deps"
require_relative "lib/ccache"
require_relative "lib/dir"

CROSS_MAKE = true
CONFIG = "x86_64_defconfig"
CONFIGS = {
  "x86_64_defconfig" => ["", ""],
  # "starfive_visionfive2_defconfig" => ["riscv", "riscv64-linux-gnu-"],
}.freeze
FILES = "*.tar"

Libexec.run("mkdir -p #{arg_dirs}")

jammy_apt
linux_deps
install_cc if CROSS_MAKE
ccc_prepare
ccc_set_limit(0, "10GiB")

Dir.chdir(BUILD_DIR) do
  clone_cmd = "git clone https://github.com/andy-shev/linux.git --depth 1"

  Libexec.run(clone_cmd) unless Libexec.code("test -d linux").zero?

  Dir.chdir("linux") do
    CONFIGS.each do |config, arr|
      arch = arr[0]
      cross = arr[1]

      config_cmd = if arch.empty?
                  "#{ccc_vendor_env} make #{config}"
                else
                  "#{ccc_vendor_env} ARCH=#{arch} make #{config}"
                end
      Libexec.code(config_cmd, Econfig)

      make_cmd = if arch.empty?
                   "#{ccc_vendor_env} make tar-pkg -j$(nproc)"
                 else
                   "#{ccc_vendor_env} ARCH=#{arch} CROSS_COMPILE=#{cross} make tar-pkg -j$(nproc)"
                 end
      result = Libexec.code(make_cmd).zero?
      next unless result

      pre = config.delete_suffix("_defconfig")
      git_rev = Libexec.output("git rev-parse --short HEAD")

      target = "../../#{TARGET_DIR}/linux/#{git_rev}/#{pre}"
      Libexec.run("mkdir -p #{target}")
      FILES.split(" ").each do |file|
        Libexec.run("cp #{file} ../../#{UPLOAD_DIR}")
        Libexec.run("mv #{file} #{target}")
      end
    end
  end
end
