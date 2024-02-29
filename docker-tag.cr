# frozen_string_literal: true

require "exec"

REGISTRY = "docker.io"
DOCKER_USER = "initdc"
DOCKER_IMAGE = "cross-make"
LATEST = "22.10-uboot"
ACTION = ""

CACHE_DIR = "cache/docker"

# https://distrowatch.com/ubuntu
VERSION = {
  "18.04": "7",
  "20.04": "9",
  "22.04": "11",
  "22.10": "12"
}

IGNORES = {
  "18.04": %w[
    lz4
    python3-asteval
    python3-sphinxcontrib.apidoc
  ]
}

TMPL = %w[
  gcc
  linux
  uboot
]

registry = ENV["REGISTRY"]? || REGISTRY
docker_user = ENV["DOCKER_USER"]? || DOCKER_USER
docker_image = ENV["DOCKER_IMAGE"]? || DOCKER_IMAGE
imagename = ENV["IMAGENAME"]? || "#{docker_user}/#{docker_image}"

Exec.run("mkdir -p #{CACHE_DIR}")

TMPL.each do |tmpl|
  tmpl_file = "Dockerfile.#{tmpl}"
  tmpl_content = File.read(tmpl_file)
  VERSION.each do |u_ver_sym, g_ver|
    u_ver = u_ver_sym.to_s
    tag = "#{u_ver}-#{tmpl}"
    tag = "#{u_ver}-#{tmpl}#{g_ver}" if tmpl == "gcc"
    dockerfile = "Dockerfile.#{tag}"
    content = tmpl_content.gsub("{version}", u_ver)
    
    ignores = IGNORES[u_ver_sym]?
    if ignores
      ignores.each do |software|
        content = content.gsub(software, "")
      end
    end

    Dir.cd CACHE_DIR do
      File.write(dockerfile, content)
      build_cmd = "docker buildx build -t #{registry}/#{imagename}:#{tag} -f #{dockerfile} . #{ACTION}"

      puts build_cmd
      # Exec.run(build_cmd)

      if tag == LATEST
        latest_cmd = "docker buildx build -t #{registry}/#{imagename}:latest -f #{dockerfile} . #{ACTION}"

        puts latest_cmd
        # Exec.run(latest_cmd)
      end
    end
  end
end
