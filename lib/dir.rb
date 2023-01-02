# frozen_string_literal: true

CACHE_DIR = "cache"
BUILD_DIR = "build"
TARGET_DIR = "target"
UPLOAD_DIR = "upload"

def arg_dirs
  "#{CACHE_DIR} #{BUILD_DIR} #{TARGET_DIR} #{UPLOAD_DIR}"
end
