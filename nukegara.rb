#!/usr/bin/env ruby
require "bundler/inline"
gemfile do
  source "https://rubygems.org"
  gem "yaml"
  gem "fileutils"
  gem "thor"
  gem "reline"
end
require "digest/md5"
require "open3"
require "pathname"
require "shellwords"
require "tmpdir"

# Use the script's directory as the root so that targets.yaml and worktree
# paths resolve consistently regardless of the current working directory.
ROOT_DIR = Pathname(__dir__).freeze

require_relative "lib/cli"

CLI.start(ARGV)
