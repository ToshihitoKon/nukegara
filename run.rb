#!/usr/bin/env ruby
require 'bundler/inline'
gemfile do
  source 'https://rubygems.org'
  gem 'yaml'
  gem 'fileutils'
  gem 'thor'
  gem 'reline'
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
    found = @hosts.select { it[:md5] == md5 }
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

module NukegaraHelpers
  private

  def colorize(text, color)
    return text unless $stdout.tty?
    codes = { red: 31, green: 32, yellow: 33, cyan: 36, gray: 90 }
    "\e[#{codes[color]}m#{text}\e[0m"
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
    puts out unless out.empty?
    true
  end

  def require_master!(config)
    return if config.master_enabled?
    warn "Error: master/ directory is not configured or does not exist."
    warn "Add 'master: { path: master/ }' to targets.yaml and create the directory."
    exit 1
  end

  def confirm_and_execute(change_labels, dry_run)
    if change_labels.empty?
      puts "Nothing to do."
      return false
    end

    change_labels.each { |l| puts "  #{l}" }

    if dry_run
      puts "\n#{change_labels.size} file(s) would be changed. Run with --execute to apply."
      return false
    end

    yes?("\nProceed with #{change_labels.size} change(s)? [y/N]")
  end
end

class Local < Thor
  include NukegaraHelpers

  def initialize(*args)
    super
    @config = NukegaraConfig.new
  end

  desc "pull", "Sync local filesystem -> env worktree"
  option :execute, type: :boolean, default: false, desc: "Actually execute (default: dry-run)"
  def pull
    dry_run = !options[:execute]

    host_config = @config.current_host_config
    @config.check_worktree_exists!(host_config)

    worktree_dir = @config.worktree_dir(host_config)
    plans = []

    host_config[:targets].each do |entry|
      realpath = File.expand_path(entry[:target])
      next unless File.exist?(realpath)

      target = Pathname(entry[:nukegara])

      if File.directory?(realpath)
        Dir.glob(File.join(realpath, '**', '*')).each do |glob|
          next if File.directory?(glob)
          relative_path = Pathname(File.dirname(glob)).relative_path_from(realpath)
          plans << { source: glob, destination: worktree_dir.join(target, relative_path, File.basename(glob)) }
        end
      else
        plans << { source: realpath, destination: worktree_dir.join(target) }
      end
    end

    changes = plans.reject { |p| p[:destination].file? && FileUtils.cmp(p[:source], p[:destination].to_s) }
    return unless confirm_and_execute(changes.map { |p| "#{p[:source]} -> #{p[:destination]}" }, dry_run)

    changes.each do |plan|
      FileUtils.mkdir_p(plan[:destination].dirname)
      FileUtils.copy(plan[:source], plan[:destination].to_s)
    end
    puts "local pull completed."
  end

  desc "apply", "Apply env worktree -> local filesystem"
  option :execute, type: :boolean, default: false, desc: "Actually execute (default: dry-run)"
  def apply
    dry_run = !options[:execute]

    host_config = @config.current_host_config
    @config.check_worktree_exists!(host_config)

    worktree_dir = @config.worktree_dir(host_config)
    plans = []

    host_config[:targets].each do |entry|
      local_base    = File.expand_path(entry[:target])
      src_base      = worktree_dir.join(entry[:nukegara])
      next unless src_base.exist?

      if src_base.file?
        plans << { src: src_base, dest: Pathname(local_base) }
      else
        src_base.glob('**/*').reject(&:directory?).each do |p|
          plans << { src: p, dest: Pathname(local_base).join(p.relative_path_from(src_base)) }
        end
      end
    end

    changes = plans.reject { |f| f[:dest].file? && FileUtils.cmp(f[:src].to_s, f[:dest].to_s) }
    return unless confirm_and_execute(changes.map { |f| "#{f[:src]} -> #{f[:dest]}" }, dry_run)

    changes.each do |f|
      FileUtils.mkdir_p(f[:dest].dirname)
      FileUtils.copy(f[:src].to_s, f[:dest].to_s)
    end
    puts "local apply completed."
  end

  desc "diff", "Show diff between local filesystem and env worktree"
  def diff
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

      (local_files.keys | env_files.keys).sort.each do |rel|
        lp    = local_files[rel]
        ep    = env_files[rel]
        label = Pathname(nukegara_base).join(rel).cleanpath.to_s

        if lp.nil?
          puts colorize("[local-missing] #{label}", :yellow)
          any_diff = true
        elsif ep.nil?
          puts colorize("[worktree-missing] #{label}", :yellow)
          any_diff = true
        else
          any_diff = true if show_diff(ep, lp, label: label, left_label: "worktree", right_label: "local")
        end
      end
    end

    puts 'No differences found.' unless any_diff
  end
end

class Nukegara < Thor
  include NukegaraHelpers

  def initialize(*args)
    super
    @config = NukegaraConfig.new
  end

  desc "diff", "Show diff between master and current env worktree"
  def diff
    require_master!(@config)
    host_config = @config.current_host_config
    @config.check_worktree_exists!(host_config)

    any_diff = false

    EffectiveConfig.compute(@config, host_config).each do |entry|
      case entry[:source]
      when :conflict
        has_diff = show_diff(entry[:master_path], entry[:env_path],
                             label: entry[:nukegara_rel],
                             left_label: "master", right_label: "env")
        if has_diff
          puts colorize("[conflict] #{entry[:nukegara_rel]}", :red)
          any_diff = true
        end
      when :env
        puts colorize("[env-only] #{entry[:nukegara_rel]}", :cyan)
      when :master
      end
    end

    puts "No conflicts found." unless any_diff
  end

  desc "apply", "Correct current env worktree to match master (overwrite conflicts)"
  option :execute, type: :boolean, default: false, desc: "Actually execute (default: dry-run)"
  def apply
    dry_run = !options[:execute]

    require_master!(@config)
    host_config = @config.current_host_config
    @config.check_worktree_exists!(host_config)

    worktree = @config.worktree_dir(host_config)
    changes = []

    EffectiveConfig.compute(@config, host_config).each do |entry|
      case entry[:source]
      when :conflict
        src, dest = entry[:master_path], entry[:env_path]
        next if FileUtils.cmp(src.to_s, dest.to_s)
        changes << { src: src, dest: dest, label: colorize("[conflict] #{entry[:nukegara_rel]}", :red) }
      when :master
        src  = entry[:master_path]
        dest = worktree.join(entry[:nukegara_rel])
        next if dest.file? && FileUtils.cmp(src.to_s, dest.to_s)
        changes << { src: src, dest: dest, label: "[master->env] #{entry[:nukegara_rel]}" }
      when :env
      end
    end

    return unless confirm_and_execute(changes.map { |c| c[:label] }, dry_run)

    changes.each do |c|
      FileUtils.mkdir_p(c[:dest].dirname)
      FileUtils.copy(c[:src].to_s, c[:dest].to_s)
    end
    puts "nukegara apply completed."
  end
end

class CLI < Thor
  desc "local SUBCOMMAND", "Manage local filesystem <-> env worktree"
  subcommand "local", Local

  desc "nukegara SUBCOMMAND", "Manage master <-> env worktrees"
  subcommand "nukegara", Nukegara
end

CLI.start(ARGV)
