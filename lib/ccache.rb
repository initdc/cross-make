# frozen_string_literal: true

require "libexec"
require_relative "error"
require_relative "sudo"

CCACHE_DIR = ENV["CCACHE_DIR"] || "#{Dir.home}/ccache"

def ccc_prepare() 
  `mkdir -p #{CCACHE_DIR}`

  cmd = "#{sudo_}apt-get install -y ccache"
  Libexec.code(cmd, Edeps)
end

def ccc_add_vendor(bin_path, name)
  `cd /usr/lib/ccache && #{sudo_}ln -s ../../bin/ccache #{name}`
  
  "PATH=/usr/lib/ccache:#{bin_path}:$PATH"
end

def ccc_set_limit(file_count, dir_size)
  `ccache -F #{file_count} -M #{dir_size}`
end

def ccc_vendor_env(*args)
  if args.empty?
    "CCACHE_DIR=#{CCACHE_DIR} PATH=/usr/lib/ccache:$PATH"
  else
    "CCACHE_DIR=#{CCACHE_DIR} #{ccc_add_vendor(args)}"
  end
end
