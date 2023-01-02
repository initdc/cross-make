# frozen_string_literal: true

require "libexec"
require_relative "error"
require_relative "sudo"

CC = %w[
  gcc-aarch64-linux-gnu
  gcc-arm-linux-gnueabi
  gcc-arm-linux-gnueabihf
  gcc-mips-linux-gnu
  gcc-mips64-linux-gnuabi64
  gcc-mips64el-linux-gnuabi64
  gcc-mipsel-linux-gnu
  gcc-powerpc-linux-gnu
  gcc-powerpc64-linux-gnu
  gcc-powerpc64le-linux-gnu
  gcc-riscv64-linux-gnu
  gcc-s390x-linux-gnu
  gcc-i686-linux-gnu
  gcc-x86-64-linux-gnu
].freeze

def install_cc
  cmd = "#{sudo_}apt-get install -y #{CC.join(" ")}"
  Libexec.code(cmd, Edeps)
end

def uboot_deps
  cmd = "#{sudo_}apt-get build-dep -y u-boot"
  Libexec.code(cmd, Edeps)
end

def linux_deps
  cmd = "#{sudo_}apt-get build-dep -y linux"
  Libexec.code(cmd, Edeps)
end

def jammy_apt
  apt = <<~EOF
    # See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to
    # newer versions of the distribution.
    deb http://archive.ubuntu.com/ubuntu/ jammy main restricted
    deb-src http://archive.ubuntu.com/ubuntu/ jammy main restricted

    ## Major bug fix updates produced after the final release of the
    ## distribution.
    deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted
    deb-src http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted

    ## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
    ## team. Also, please note that software in universe WILL NOT receive any
    ## review or updates from the Ubuntu security team.
    deb http://archive.ubuntu.com/ubuntu/ jammy universe
    deb-src http://archive.ubuntu.com/ubuntu/ jammy universe
    deb http://archive.ubuntu.com/ubuntu/ jammy-updates universe
    deb-src http://archive.ubuntu.com/ubuntu/ jammy-updates universe

    ## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
    ## team, and may not be under a free licence. Please satisfy yourself as to
    ## your rights to use the software. Also, please note that software in
    ## multiverse WILL NOT receive any review or updates from the Ubuntu
    ## security team.
    deb http://archive.ubuntu.com/ubuntu/ jammy multiverse
    deb-src http://archive.ubuntu.com/ubuntu/ jammy multiverse
    deb http://archive.ubuntu.com/ubuntu/ jammy-updates multiverse
    deb-src http://archive.ubuntu.com/ubuntu/ jammy-updates multiverse

    ## N.B. software from this repository may not have been tested as
    ## extensively as that contained in the main release, although it includes
    ## newer versions of some applications which may provide useful features.
    ## Also, please note that software in backports WILL NOT receive any review
    ## or updates from the Ubuntu security team.
    deb http://archive.ubuntu.com/ubuntu/ jammy-backports main restricted universe multiverse
    deb-src http://archive.ubuntu.com/ubuntu/ jammy-backports main restricted universe multiverse

    deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted
    deb-src http://security.ubuntu.com/ubuntu/ jammy-security main restricted
    deb http://security.ubuntu.com/ubuntu/ jammy-security universe
    deb-src http://security.ubuntu.com/ubuntu/ jammy-security universe
    deb http://security.ubuntu.com/ubuntu/ jammy-security multiverse
    deb-src http://security.ubuntu.com/ubuntu/ jammy-security multiverse
  EOF

  output = Libexec.output("cat /etc/lsb-release | grep CODENAME")
  jammy = output.split("=")[1] == "jammy"

  unless Libexec.code("test -f /etc/apt/sources.list.orig").zero?
    backup = "#{sudo_}cp /etc/apt/sources.list /etc/apt/sources.list.orig"
    Libexec.run(backup)
  end

  cmd = if jammy
          "#{sudo_}sed -i 's/# deb-src/deb-src/g' /etc/apt/sources.list"
        else
          "#{sudo_}echo > /etc/apt/sources.list '#{apt}'"
        end

  Libexec.code(cmd, Eapt)
  Libexec.run("#{sudo_}apt-get update")
end
