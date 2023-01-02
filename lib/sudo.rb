# frozen_string_literal: true

require "libexec"

def sudo_
  Libexec.output("id -u") == "0" ? "" : "sudo "
end
