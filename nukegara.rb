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

# Use the script's directory as the root so that targets.yaml and worktree
# paths resolve consistently regardless of the current working directory.
ROOT_DIR = Pathname(__dir__).freeze

class NukegaraConfig
  attr_reader :hosts

  def initialize(yaml_path = ROOT_DIR.join("targets.yaml"))
    raw = YAML.load(File.read(yaml_path.to_s), symbolize_names: true)
    @master_path = raw.dig(:master, :path)
    @hosts = raw[:hosts]
  end

  def master_enabled?
    !@master_path.nil? && master_dir_path.directory?
  end

  def master_dir
    master_dir_path if master_enabled?
  end

  def current_host_config
    md5 = host_md5
    matched_hosts = @hosts.select { it[:md5] == md5 }
    if matched_hosts.size != 1
      warn "Error: Expected exactly one host configuration for this machine."
      warn "MD5: #{md5}"
      exit 1
    end
    matched_hosts.first
  end

  def worktree_dir(host_config)
    ROOT_DIR.join(host_config[:branch])
  end

  def check_worktree_exists!(host_config)
    return if worktree_dir(host_config).directory?

    warn "Error: Git worktree for branch #{host_config[:branch]} does not exist."
    warn "Please create worktree: git worktree add #{host_config[:branch]} #{host_config[:branch]}"
    exit 1
  end

  private

  # Resolve a relative master_path against the root. An absolute master_path
  # is used as-is (Pathname#join keeps the absolute argument).
  def master_dir_path
    ROOT_DIR.join(@master_path)
  end

  def host_md5
    hostname = `uname -n`.strip
    Digest::MD5.hexdigest(hostname)
  end
end

# Collects the files under a base path into a Hash keyed by path relative to
# the base. A single regular file is keyed as ".". The single source of truth
# for how files are enumerated, so every command sees the same set.
#
# exclude is an optional list of glob patterns (File.fnmatch syntax, matched
# against the base-relative path). Matching files are dropped from the result,
# so every command consistently skips them (e.g. log files under config dirs).
module PathCollector
  module_function

  def collect_files(base_path, exclude = nil)
    return {} if base_path.nil? || !base_path.exist?

    if base_path.file?
      { "." => base_path }
    else
      base_path.glob("**/*")
               .reject(&:directory?)
               .each_with_object({}) do |path, files|
                 rel = path.relative_path_from(base_path).to_s
                 next if excluded?(rel, exclude)

                 files[rel] = path
               end
    end
  end

  # A path is excluded when it matches any glob pattern. FNM_PATHNAME keeps
  # `*` from crossing `/`, so `*.log` matches only top-level files while
  # `**/*.log` reaches into subdirectories.
  def excluded?(rel, exclude)
    return false if exclude.nil? || exclude.empty?

    exclude.any? { |pattern| File.fnmatch?(pattern, rel, File::FNM_PATHNAME | File::FNM_EXTGLOB) }
  end

  # Resolves a relative key from collect_files back to a real path under base.
  # A "." key means base itself was a single file, so base is returned as-is.
  def resolve(base, rel)
    rel == "." ? Pathname(base) : Pathname(base).join(rel)
  end
end

# Cross-references master/ and the env worktree for every target file,
# classifying each as :conflict (in both), :env (env-only), or :master
# (master-only). This classification drives the diff/promote/apply commands.
class EffectiveConfig
  include PathCollector

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
      exclude       = entry[:exclude]

      master_files = collect_files(@master_dir&.join(nukegara_base), exclude)
      env_files    = collect_files(@worktree_dir.join(nukegara_base), exclude)

      all_rel = (master_files.keys | env_files.keys).sort

      all_rel.each do |rel|
        master_path = master_files[rel]
        env_path    = env_files[rel]

        source = if master_path && env_path
                   :conflict
                 elsif env_path
                   :env
                 else
                   :master
                 end

        effective_path = master_path || env_path

        rel_clean = Pathname(nukegara_base).join(rel).cleanpath.to_s
        local_path = resolve(local_base, rel)

        results << {
          nukegara_rel: rel_clean,
          local_path: local_path,
          effective_path: effective_path,
          source: source,
          master_path: master_path,
          env_path: env_path
        }
      end
    end

    results
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
    rescue StandardError
      # cmp raises when a file is missing or unreadable; treat that as
      # "differs" and fall through to show the diff.
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

  # Copies each change's :src to its :dest, creating parent directories.
  def apply_changes(changes)
    changes.each do |change|
      FileUtils.mkdir_p(change[:dest].dirname)
      FileUtils.copy(change[:src].to_s, change[:dest].to_s)
    end
  end
end

class Local < Thor
  include NukegaraHelpers
  include PathCollector

  def initialize(*args)
    super
    @config = NukegaraConfig.new
  end

  desc "pull", "Sync local filesystem -> env worktree"
  option :execute, type: :boolean, default: false, desc: "Actually execute (default: dry-run)"
  def pull
    sync(direction: :pull)
  end

  desc "apply", "Apply env worktree -> local filesystem"
  option :execute, type: :boolean, default: false, desc: "Actually execute (default: dry-run)"
  def apply
    sync(direction: :apply)
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
      exclude       = entry[:exclude]

      local_files = collect_files(Pathname(local_base), exclude)
      env_files   = collect_files(worktree_dir.join(nukegara_base), exclude)

      (local_files.keys | env_files.keys).sort.each do |rel|
        local_path = local_files[rel]
        env_path   = env_files[rel]
        label      = Pathname(nukegara_base).join(rel).cleanpath.to_s

        if local_path.nil?
          puts colorize("[local-missing] #{label}", :yellow)
          any_diff = true
        elsif env_path.nil?
          puts colorize("[worktree-missing] #{label}", :yellow)
          any_diff = true
        elsif show_diff(env_path, local_path, label: label, left_label: "worktree", right_label: "local")
          any_diff = true
        end
      end
    end

    puts "No differences found." unless any_diff
  end

  private

  # pull copies local -> worktree, apply copies worktree -> local. Both walk
  # the same target list and differ only in which side is the source.
  def sync(direction:)
    dry_run = !options[:execute]

    host_config = @config.current_host_config
    @config.check_worktree_exists!(host_config)

    worktree_dir = @config.worktree_dir(host_config)
    changes = []

    host_config[:targets].each do |entry|
      local_base = File.expand_path(entry[:target])
      env_base   = worktree_dir.join(entry[:nukegara])
      src_base   = direction == :pull ? Pathname(local_base) : env_base

      collect_files(src_base, entry[:exclude]).each do |rel, src|
        dest_base = direction == :pull ? env_base : Pathname(local_base)
        dest = resolve(dest_base, rel)
        next if dest.file? && FileUtils.cmp(src.to_s, dest.to_s)

        changes << { src: src, dest: dest }
      end
    end

    return unless confirm_and_execute(changes.map { "#{it[:src]} -> #{it[:dest]}" }, dry_run)

    apply_changes(changes)
    puts "local #{direction} completed."
  end
end

class Master < Thor
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
        # master-only files are not a conflict; nothing to report here.
      end
    end

    puts "No conflicts found." unless any_diff
  end

  desc "promote [NUKEGARA_REL]",
       "Promote env to master. No args: dry-run all conflicts. With path: promote specific file (conflict or env-only)"
  option :execute, type: :boolean, default: false, desc: "Actually execute (default: dry-run)"
  def promote(nukegara_rel = nil)
    require_master!(@config)
    host_config = @config.current_host_config
    @config.check_worktree_exists!(host_config)

    all_entries = EffectiveConfig.compute(@config, host_config)

    if nukegara_rel.nil?
      promote_all(all_entries)
    else
      promote_one(all_entries, nukegara_rel)
    end
  end

  desc "apply", "Overwrite current env worktree to match master (overwrite conflicts)"
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
        src = entry[:master_path]
        dest = entry[:env_path]
        next if FileUtils.cmp(src.to_s, dest.to_s)

        changes << { src: src, dest: dest, label: colorize("[conflict] #{entry[:nukegara_rel]}", :red) }
      when :master
        src  = entry[:master_path]
        dest = worktree.join(entry[:nukegara_rel])
        next if dest.file? && FileUtils.cmp(src.to_s, dest.to_s)

        changes << { src: src, dest: dest, label: "[master->env] #{entry[:nukegara_rel]}" }
      when :env
        # env-only files are left untouched; apply only flows master -> env.
      end
    end

    return unless confirm_and_execute(changes.map { |change| change[:label] }, dry_run)

    apply_changes(changes)
    puts "master apply completed."
  end

  private

  # Promotes every conflicting file (env content wins) to master.
  def promote_all(all_entries)
    dry_run = !options[:execute]

    changes = all_entries.select { |e| e[:source] == :conflict }.filter_map do |e|
      next if FileUtils.cmp(e[:master_path].to_s, e[:env_path].to_s)

      { src: e[:env_path], dest: e[:master_path], label: colorize("[conflict] #{e[:nukegara_rel]}", :red) }
    end

    return unless confirm_and_execute(changes.map { |change| change[:label] }, dry_run)

    apply_changes(changes)
    puts "master promote completed."
  end

  # Promotes a single file (conflict or env-only) to master.
  def promote_one(all_entries, nukegara_rel)
    dry_run = !options[:execute]

    entry = all_entries.find do |e|
      e[:nukegara_rel] == nukegara_rel && [:conflict, :env].include?(e[:source])
    end
    unless entry
      warn "Error: '#{nukegara_rel}' is not promotable (not found or master-only)."
      exit 1
    end

    src  = entry[:env_path]
    dest = entry[:source] == :conflict ? entry[:master_path] : @config.master_dir.join(nukegara_rel)

    if entry[:source] == :conflict
      show_diff(entry[:master_path], entry[:env_path],
                label: nukegara_rel, left_label: "master", right_label: "env")
    end

    return unless confirm_and_execute(["#{src} -> #{dest}"], dry_run)

    apply_changes([{ src: src, dest: dest }])
    puts "master promote completed."
  end
end

# Wraps the git operations on the env worktree that the workflow would
# otherwise run by hand (cd worktree; git add/commit/push). The branch and
# worktree path both come from targets.yaml, so no arguments are needed.
class Git < Thor
  include NukegaraHelpers

  def initialize(*args)
    super
    @config = NukegaraConfig.new
  end

  desc "status", "Show git status of the env worktree"
  def status
    host_config = @config.current_host_config
    @config.check_worktree_exists!(host_config)

    run_git(host_config, "status", "-sb")
  end

  desc "stage", "Stage all changes in the env worktree (git add -A)"
  def stage
    host_config = @config.current_host_config
    @config.check_worktree_exists!(host_config)

    dirty = run_git(host_config, "status", "--porcelain", capture: true)
    abort("Nothing to stage.") if dirty.strip.empty?

    run_git(host_config, "add", "-A")
    run_git(host_config, "status", "-sb")
  end

  # Default commit message used when -m is omitted, matching the manual
  # workflow this helper replaces.
  DEFAULT_COMMIT_MESSAGE = "update dotfiles".freeze

  desc "commit", "Commit the staged changes in the env worktree"
  option :message, type: :string, aliases: "-m", desc: "Commit message (default: \"#{DEFAULT_COMMIT_MESSAGE}\")"
  def commit
    host_config = @config.current_host_config
    @config.check_worktree_exists!(host_config)

    abort("Nothing staged to commit. Run `git stage` first.") unless anything_staged?(host_config)

    message = options[:message] || DEFAULT_COMMIT_MESSAGE
    run_git(host_config, "commit", "-m", message)
  end

  desc "push", "Push the env worktree branch to its remote"
  def push
    host_config = @config.current_host_config
    @config.check_worktree_exists!(host_config)

    run_git(host_config, "push")
  end

  desc "setup", "Create the env worktree for this host's configured branch"
  def setup
    host_config = @config.current_host_config
    branch = host_config[:branch]
    worktree = @config.worktree_dir(host_config)

    if worktree.directory?
      puts "Worktree already exists: #{worktree}"
      return
    end

    # A worktree can only be added for a branch git already knows about. Create
    # and publish the branch first when neither the local nor the remote ref
    # exists yet, so a brand-new environment works from a single command.
    create_branch_if_missing(branch)

    git_in_root("worktree", "add", branch, branch)
    puts "Worktree created: #{worktree}"
  end

  private

  # Runs git inside the env worktree. Returns captured stdout when capture is
  # true; otherwise streams output and aborts on a non-zero exit.
  def run_git(host_config, *git_args, capture: false)
    worktree = @config.worktree_dir(host_config)

    if capture
      out, = Open3.capture2("git", "-C", worktree.to_s, *git_args)
      return out
    end

    system("git", "-C", worktree.to_s, *git_args) || abort("git #{git_args.first} failed.")
  end

  # True when the env worktree has staged changes. `git diff --cached --quiet`
  # exits 0 when nothing is staged and 1 when there is, so a successful exit
  # means the index is clean.
  def anything_staged?(host_config)
    worktree = @config.worktree_dir(host_config)
    !system("git", "-C", worktree.to_s, "diff", "--cached", "--quiet")
  end

  # Runs git from the repository root (for operations that act on the repo
  # rather than a worktree, such as creating worktrees and branches).
  def git_in_root(*git_args)
    system("git", "-C", ROOT_DIR.to_s, *git_args) || abort("git #{git_args.first} failed.")
  end

  def create_branch_if_missing(branch)
    return if branch_known?(branch)

    git_in_root("branch", branch)
    git_in_root("push", "-u", "origin", branch)
  end

  # True when the branch exists locally or on the origin remote.
  def branch_known?(branch)
    local, = Open3.capture2("git", "-C", ROOT_DIR.to_s,
                            "rev-parse", "--verify", "--quiet", branch)
    return true unless local.strip.empty?

    remote, = Open3.capture2("git", "-C", ROOT_DIR.to_s,
                             "ls-remote", "--heads", "origin", branch)
    !remote.strip.empty?
  end
end

class CLI < Thor
  include NukegaraHelpers
  include PathCollector

  def initialize(*args)
    super
    @config = NukegaraConfig.new
  end

  desc "local SUBCOMMAND", "Manage local filesystem <-> env worktree"
  subcommand "local", Local

  desc "master SUBCOMMAND", "Manage master <-> env worktrees"
  subcommand "master", Master

  desc "git SUBCOMMAND", "Run git operations on the env worktree (status/stage/commit/push/setup)"
  subcommand "git", Git

  desc "health", "Show a one-line diff summary across stages (local <-> env <-> master)"
  def health
    host_config = @config.current_host_config
    @config.check_worktree_exists!(host_config)

    local_env  = format_stage("local<->env", local_env_counts(host_config))
    env_master = if @config.master_enabled?
                   format_stage("env<->master", env_master_counts(host_config))
                 else
                   "env<->master skipped"
                 end

    puts "health: #{local_env} / #{env_master}"
  end

  private

  # Counts how local and the env worktree diverge: files present on only one
  # side (missing) and files present on both but differing in content.
  def local_env_counts(host_config)
    worktree_dir = @config.worktree_dir(host_config)
    counts = Hash.new(0)

    host_config[:targets].each do |entry|
      local_files = collect_files(Pathname(File.expand_path(entry[:target])), entry[:exclude])
      env_files   = collect_files(worktree_dir.join(entry[:nukegara]), entry[:exclude])

      (local_files.keys | env_files.keys).each do |rel|
        local_path = local_files[rel]
        env_path   = env_files[rel]

        if local_path.nil? || env_path.nil?
          counts[:missing] += 1
        elsif !FileUtils.cmp(local_path.to_s, env_path.to_s)
          counts[:differ] += 1
        end
      end
    end

    counts
  end

  # Counts conflicts between master and the env worktree (files in both whose
  # content differs). env-only files are healthy (just not promoted yet) and
  # master-only files are not conflicts, so neither is counted.
  def env_master_counts(host_config)
    counts = Hash.new(0)

    EffectiveConfig.compute(@config, host_config).each do |entry|
      next unless entry[:source] == :conflict

      counts[:conflict] += 1 unless FileUtils.cmp(entry[:master_path].to_s, entry[:env_path].to_s)
    end

    counts
  end

  def format_stage(label, counts)
    total = counts.values.sum
    return colorize("#{label} OK", :green) if total.zero?

    detail = counts.reject { |_, n| n.zero? }
                   .map { |kind, n| "#{n} #{kind.to_s.tr('_', '-')}" }
                   .join(", ")
    colorize("#{label} #{detail}", :yellow)
  end
end

CLI.start(ARGV)
