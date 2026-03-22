#!/usr/bin/env ruby
require 'bundler/inline'
gemfile do
  source 'https://rubygems.org'
  gem 'yaml'
  gem 'fileutils'
end
require 'digest/md5'
require 'open3'
require 'pathname'

class NukegaraConfig
  attr_reader :hosts

  def initialize(yaml_path = 'targets.yaml')
    raw = YAML.load(File.read(yaml_path), symbolize_names: true)
    @master_path = raw.dig(:master, :path)
    @hosts = raw[:hosts]
  end

  def master_enabled?
    !@master_path.nil? && Dir.exist?(@master_path)
  end

  def master_dir
    Pathname(@master_path) if master_enabled?
  end

  def current_host_config
    md5 = host_md5
    found = @hosts.select { |h| h[:md5] == md5 }
    if found.size != 1
      warn "Error: Expected exactly one host configuration for this machine."
      warn "MD5: #{md5}"
      exit 1
    end
    found.first
  end

  def worktree_dir(host_config)
    Pathname('.').join(host_config[:branch])
  end

  def check_worktree_exists!(host_config)
    return if worktree_dir(host_config).directory?
    warn "Error: Git worktree for branch #{host_config[:branch]} does not exist."
    warn "Please create worktree: git worktree add #{host_config[:branch]} #{host_config[:branch]}"
    exit 1
  end

  private

  def host_md5
    hostname = `uname -n`.strip
    Digest::MD5.hexdigest(hostname)
  end
end

class EffectiveConfig
  def self.compute(config, host_config)
    new(config, host_config).compute
  end

  def initialize(config, host_config)
    @config = config
    @host_config = host_config
    @worktree_dir = config.worktree_dir(host_config)
    @master_dir = config.master_dir
  end

  def compute
    results = []

    @host_config[:targets].each do |entry|
      nukegara_base = entry[:nukegara]
      local_base    = File.expand_path(entry[:target])

      master_files = collect_files(@master_dir&.join(nukegara_base))
      env_files    = collect_files(@worktree_dir.join(nukegara_base))

      all_rel = (master_files.keys | env_files.keys).sort

      all_rel.each do |rel|
        mp = master_files[rel]
        ep = env_files[rel]

        source = if mp && ep
                   :conflict
                 elsif ep
                   :env
                 else
                   :master
                 end

        effective = mp || ep

        rel_clean = Pathname(nukegara_base).join(rel).cleanpath.to_s
        local_path = if rel == '.'
                       Pathname(local_base)
                     else
                       Pathname(local_base).join(rel)
                     end

        results << {
          nukegara_rel:   rel_clean,
          local_path:     local_path,
          effective_path: effective,
          source:         source,
          master_path:    mp,
          env_path:       ep,
        }
      end
    end

    results
  end

  private

  def collect_files(base_path)
    return {} if base_path.nil? || !base_path.exist?

    if base_path.file?
      { '.' => base_path }
    else
      base_path.glob('**/*')
               .reject(&:directory?)
               .each_with_object({}) do |p, h|
                 h[p.relative_path_from(base_path).to_s] = p
               end
    end
  end
end

class Commands
  def initialize(config)
    @config = config
  end

  def local_pull
    host_config = @config.current_host_config
    @config.check_worktree_exists!(host_config)

    plans = build_local_to_worktree_plans(host_config)
    plans.each do |plan|
      dest_dir = plan[:destination].dirname
      FileUtils.mkdir_p(dest_dir) unless dest_dir.directory?

      if plan[:destination].file? && FileUtils.cmp(plan[:source], plan[:destination].to_s)
        puts "Skip (unchanged): #{plan[:source]}"
        next
      end

      puts "Pull: #{plan[:source]} -> #{plan[:destination]}"
      FileUtils.copy(plan[:source], plan[:destination].to_s)
    end
    puts 'local pull completed.'
  end

  def local_apply
    host_config = @config.current_host_config
    @config.check_worktree_exists!(host_config)

    worktree_dir = @config.worktree_dir(host_config)

    host_config[:targets].each do |entry|
      local_base    = File.expand_path(entry[:target])
      nukegara_base = entry[:nukegara]
      src_base      = worktree_dir.join(nukegara_base)

      unless src_base.exist?
        puts "Skip (not in worktree): #{nukegara_base}"
        next
      end

      files = if src_base.file?
                [{ src: src_base, dest: Pathname(local_base) }]
              else
                src_base.glob('**/*').reject(&:directory?).map do |p|
                  rel = p.relative_path_from(src_base)
                  { src: p, dest: Pathname(local_base).join(rel) }
                end
              end

      files.each do |f|
        FileUtils.mkdir_p(f[:dest].dirname)
        if f[:dest].file? && FileUtils.cmp(f[:src].to_s, f[:dest].to_s)
          puts "Skip (unchanged): #{f[:dest]}"
          next
        end
        puts "Apply: #{f[:src]} -> #{f[:dest]}"
        FileUtils.copy(f[:src].to_s, f[:dest].to_s)
      end
    end
    puts 'local apply completed.'
  end

  def local_diff
    host_config = @config.current_host_config
    @config.check_worktree_exists!(host_config)

    worktree_dir = @config.worktree_dir(host_config)
    any_diff = false

    host_config[:targets].each do |entry|
      local_base    = File.expand_path(entry[:target])
      nukegara_base = entry[:nukegara]
      env_base      = worktree_dir.join(nukegara_base)

      local_files = if File.file?(local_base)
                      { '.' => Pathname(local_base) }
                    elsif File.directory?(local_base)
                      Pathname(local_base).glob('**/*').reject(&:directory?).each_with_object({}) do |p, h|
                        h[p.relative_path_from(local_base).to_s] = p
                      end
                    else
                      {}
                    end

      env_files = if env_base.file?
                    { '.' => env_base }
                  elsif env_base.directory?
                    env_base.glob('**/*').reject(&:directory?).each_with_object({}) do |p, h|
                      h[p.relative_path_from(env_base).to_s] = p
                    end
                  else
                    {}
                  end

      all_rel = (local_files.keys | env_files.keys).sort

      all_rel.each do |rel|
        lp = local_files[rel]
        ep = env_files[rel]
        label = Pathname(nukegara_base).join(rel).cleanpath.to_s

        if lp.nil?
          puts colorize("[local-missing] #{label}", :yellow)
          any_diff = true
        elsif ep.nil?
          puts colorize("[worktree-missing] #{label}", :yellow)
          any_diff = true
        else
          d = show_diff(ep, lp, label: label, left_label: "worktree", right_label: "local")
          any_diff = true if d
        end
      end
    end

    puts 'No differences found.' unless any_diff
  end

  def nukegara_diff
    require_master!

    any_diff = false

    @config.hosts.each do |host_config|
      branch = host_config[:branch]
      worktree = @config.worktree_dir(host_config)
      unless worktree.directory?
        puts colorize("[worktree-missing] #{branch}", :yellow)
        next
      end

      puts "\n=== #{branch} ==="
      entries = EffectiveConfig.compute(@config, host_config)

      entries.each do |entry|
        case entry[:source]
        when :conflict
          puts colorize("[conflict] #{entry[:nukegara_rel]}", :red)
          d = show_diff(entry[:master_path], entry[:env_path],
                        label: entry[:nukegara_rel],
                        left_label: "master", right_label: "env")
          any_diff = true if d
        when :env
          puts colorize("[env-only] #{entry[:nukegara_rel]}", :cyan)
        when :master
        end
      end
    end

    puts "\nNo conflicts found." unless any_diff
  end

  def nukegara_apply
    require_master!

    @config.hosts.each do |host_config|
      branch = host_config[:branch]
      worktree = @config.worktree_dir(host_config)
      unless worktree.directory?
        puts colorize("[skip] worktree not found: #{branch}", :yellow)
        next
      end

      puts "\n=== #{branch} ==="
      entries = EffectiveConfig.compute(@config, host_config)

      entries.each do |entry|
        case entry[:source]
        when :conflict
          dest = entry[:env_path]
          src  = entry[:master_path]
          if FileUtils.cmp(src.to_s, dest.to_s)
            puts "Skip (unchanged): #{entry[:nukegara_rel]}"
          else
            puts colorize("Correct (conflict): #{entry[:nukegara_rel]}", :red)
            FileUtils.copy(src.to_s, dest.to_s)
          end
        when :master
          dest = worktree.join(entry[:nukegara_rel])
          src  = entry[:master_path]
          FileUtils.mkdir_p(dest.dirname)
          if dest.file? && FileUtils.cmp(src.to_s, dest.to_s)
            puts "Skip (unchanged): #{entry[:nukegara_rel]}"
          else
            puts "Apply (master->env): #{entry[:nukegara_rel]}"
            FileUtils.copy(src.to_s, dest.to_s)
          end
        when :env
        end
      end
    end

    puts "\nnukegara apply completed."
  end

  private

  def require_master!
    return if @config.master_enabled?
    warn "Error: master/ directory is not configured or does not exist."
    warn "Add 'master: { path: master/ }' to targets.yaml and create the directory."
    exit 1
  end

  def build_local_to_worktree_plans(host_config)
    worktree_dir = @config.worktree_dir(host_config)
    plans = []

    host_config[:targets].each do |entry|
      realpath = File.expand_path(entry[:target])
      unless File.exist?(realpath)
        puts "Skip (not found locally): #{realpath}"
        next
      end

      target = Pathname(entry[:nukegara])

      if File.directory?(realpath)
        Dir.glob(File.join(realpath, '**', '*')).each do |glob|
          next if File.directory?(glob)
          relative_path = Pathname(File.dirname(glob)).relative_path_from(realpath)
          plans << {
            source:      glob,
            destination: worktree_dir.join(target, relative_path, File.basename(glob))
          }
        end
      else
        plans << {
          source:      realpath,
          destination: worktree_dir.join(target)
        }
      end
    end

    plans
  end

  def show_diff(path_a, path_b, label:, left_label: "a", right_label: "b")
    begin
      return false if FileUtils.cmp(path_a.to_s, path_b.to_s)
    rescue
    end

    out, = Open3.capture2("diff", "--unified=3",
                          "--label", "#{left_label}/#{label}",
                          "--label", "#{right_label}/#{label}",
                          path_a.to_s, path_b.to_s)
    unless out.empty?
      puts out
    end
    true
  end

  def colorize(text, color)
    return text unless $stdout.tty?
    codes = { red: 31, green: 32, yellow: 33, cyan: 36, gray: 90 }
    "\e[#{codes[color]}m#{text}\e[0m"
  end
end

USAGE = <<~USAGE
  nukegara - dotfile manager

  Usage: ruby run.rb <context> <action>

  Contexts and actions:
    local pull    - Sync local filesystem -> env worktree
    local apply   - Apply env worktree -> local filesystem
    local diff    - Show diff between local filesystem and env worktree

    nukegara diff   - Show diff between master and each env worktree
    nukegara apply  - Correct env worktrees to match master (overwrite conflicts)
USAGE

config = NukegaraConfig.new
commands = Commands.new(config)

context = ARGV[0]
action  = ARGV[1]

if context.nil? || action.nil?
  puts USAGE
  exit 0
end

case [context, action]
when ['local', 'pull']
  commands.local_pull
when ['local', 'apply']
  commands.local_apply
when ['local', 'diff']
  commands.local_diff
when ['nukegara', 'diff']
  commands.nukegara_diff
when ['nukegara', 'apply']
  commands.nukegara_apply
else
  warn "Unknown command: #{context} #{action}"
  puts USAGE
  exit 1
end
