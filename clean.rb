# frozen_string_literal: true

require "libexec"
require_relative "lib/dir"

Libexec.run("rm -rf #{UPLOAD_DIR} #{TARGET_DIR}")