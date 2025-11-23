# usr/bin/env ruby
require "bundler/inline"
gemfile do
  source "https://rubygems.org"
  gem "yaml"
  gem "fileutils"
end
require "digest/md5"

def host_md5
  hostname = `hostname`.strip
  Digest::MD5.hexdigest(hostname)
end

def host_config(config)
  found_configs = config.select do
    it[:md5] == host_md5
  end
  if found_configs.size != 1
    puts "Error: Expected exactly one host configuration for this machine."
    puts "MD5: #{host_md5}"
    exit 1
  end
  found_configs.first
end

def git_exist_target_worktree?(host_config)
  Pathname(".").join(host_config[:branch]).directory?
end

def sync_plans(host_config)
  worktree_dir = Pathname(".").join(host_config[:branch])
  plans = []

  host_config[:targets].each do |entry|
    realpath = File.expand_path(entry[:target])
    unless File.exist?(realpath)
      puts "Skipping #{realpath} as it does not exist."
      next
    end

    target = Pathname(entry[:nukegara])

    if File.directory?(realpath)
      puts "target #{realpath} is a directory."
      basepath = Pathname(realpath)

      globs = Dir.glob(File.join(realpath, "**", "*"))
      globs.each do |glob|
        next if File.directory?(glob)

        relative_path = Pathname(File.dirname(glob)).relative_path_from(basepath)
        plans << {
          source: glob,
          destination: worktree_dir.join(target, relative_path, File.basename(glob))
        }
      end
    else
      puts "target #{realpath} is a file."
      plans << {
        source: realpath,
        destination: worktree_dir.join(target)
      }
    end
  end
  plans
end

# main
config = YAML.load(File.read("targets.yaml"), symbolize_names: true)
host_config = host_config(config[:hosts])
unless git_exist_target_worktree?(host_config)
  puts "Error: Git worktree for branch #{host_config[:branch]} does not exist."
  puts "Please create worktree directory #{host_config[:branch]} and try again."
  exit 1
end

plans = sync_plans(host_config)
plans.each do |plan|
  dest_dir = plan[:destination].dirname
  unless Dir.exist?(dest_dir)
    puts "Creating directory #{dest_dir}"
    FileUtils.mkdir_p(dest_dir)
  end

  if File.file?(plan[:destination]) && FileUtils.cmp(plan[:source], plan[:destination])
    puts "Skipping #{plan[:source]} is not changed."
    next
  end

  puts "Syncing #{plan[:source]} to #{plan[:destination]}"
  FileUtils.copy(plan[:source], plan[:destination])
end

puts "Sync completed."
