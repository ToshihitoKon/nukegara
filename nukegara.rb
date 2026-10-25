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

  # A file that cannot be read (e.g. a dangling symlink) counts as differing,
  # so one broken file does not abort the whole listing.
  def same_content?(path_a, path_b)
    FileUtils.cmp(path_a.to_s, path_b.to_s)
  rescue SystemCallError
    false
  end
end

# Read-only git queries on the env worktree, shared by `git status` and
# `health` so both judge the worktree the same way.
module WorktreeGit
  module_function

  # Porcelain v1 lines ("XY PATH"), one per changed or untracked file.
  def worktree_changes(worktree)
    out, = Open3.capture2("git", "-C", worktree.to_s, "status", "--porcelain")
    out.lines
  end

  # Returns [behind, ahead] commit counts against the upstream's
  # remote-tracking ref, matching the [ahead N, behind M] of `status -sb`.
  # A branch without an upstream makes rev-list fail; that counts as [0, 0]
  # and its stderr is dropped so the caller's output stays clean.
  def upstream_divergence(worktree)
    out, exit_status = Open3.capture2("git", "-C", worktree.to_s,
                                      "rev-list", "--left-right", "--count", "@{upstream}...HEAD",
                                      err: File::NULL)
    return [0, 0] unless exit_status.success?

    out.split.map(&:to_i)
  end

  # Updates the remote-tracking ref so upstream_divergence sees pushes made
  # from other machines. stderr is dropped because the caller reports a
  # failure (e.g. offline) itself.
  def fetch_upstream(worktree)
    system("git", "-C", worktree.to_s, "fetch", "--quiet", err: File::NULL)
  end
end

# Cross-references master/ and the env worktree for every target file,
# classifying each as :conflict (in both), :env (env-only), or :master
# (master-only). This classification drives every master command and health.
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

# Compares the local filesystem with the env worktree for every target file
# and lists the files that differ, classifying each as :local_missing,
# :worktree_missing or :differ. Shared by `local status`, `local diff` and
# `health` so all of them report the same set of files.
class LocalEnvDiff
  include PathCollector

  def self.compute(config, host_config)
    new(config, host_config).compute
  end

  def initialize(config, host_config)
    @host_config  = host_config
    @worktree_dir = config.worktree_dir(host_config)
  end

  def compute
    results = []

    @host_config[:targets].each do |entry|
      local_base    = File.expand_path(entry[:target])
      nukegara_base = entry[:nukegara]
      exclude       = entry[:exclude]

      local_files = collect_files(Pathname(local_base), exclude)
      env_files   = collect_files(@worktree_dir.join(nukegara_base), exclude)

      (local_files.keys | env_files.keys).sort.each do |rel|
        local_path = local_files[rel]
        env_path   = env_files[rel]

        kind = if local_path.nil?
                 :local_missing
               elsif env_path.nil?
                 :worktree_missing
               elsif !same_content?(local_path, env_path)
                 :differ
               end
        next if kind.nil?

        results << {
          nukegara_rel: Pathname(nukegara_base).join(rel).cleanpath.to_s,
          kind: kind,
          local_path: local_path,
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

  # Shows the diffs of [nukegara_rel, left_path, right_path] files as a single
  # `git diff --no-index` over two scratch trees of copies, so git's own pager,
  # colors and config apply to all of them at once. Running git per file would
  # open a pager per file, and giving git the real paths would diff a symlink
  # as the link instead of the content status and pull/apply follow it to.
  def show_diffs(left_label, right_label, files)
    Dir.mktmpdir("nukegara-diff") do |dir|
      # Both trees must exist even when every file is missing on one side,
      # since git refuses to compare a directory that does not exist.
      FileUtils.mkdir_p([File.join(dir, left_label), File.join(dir, right_label)])
      files.each do |rel, left_path, right_path|
        copy_for_diff(left_path, File.join(dir, left_label, rel))
        copy_for_diff(right_path, File.join(dir, right_label, rel))
      end

      # The tree names already tell the sides apart, so git's a/ b/ prefixes
      # are dropped. --no-renames keeps a file that exists on one side only
      # from being paired with a similar file on the other.
      system("git", "-C", dir, "diff", "--no-index", "--no-prefix", "--no-renames", "--",
             left_label, right_label)
    end
  end

  # A side that is missing or unreadable (e.g. a dangling symlink) is left out
  # of the scratch tree, so git shows the other side as added or deleted. Only
  # the content is copied: FileUtils.cp would carry the mode over and make git
  # report mode changes that status and pull/apply never look at.
  def copy_for_diff(src, dest)
    return if src.nil? || !File.readable?(src)

    FileUtils.mkdir_p(File.dirname(dest))
    IO.copy_stream(src.to_s, dest)
  end

  # Conflicts whose master and env copies actually differ. A conflict with the
  # same content on both sides needs neither promote nor apply.
  def differing_conflicts(entries)
    entries.select do |entry|
      entry[:source] == :conflict && !PathCollector.same_content?(entry[:master_path], entry[:env_path])
    end
  end

  def require_master!(config)
    return if config.master_enabled?

    warn "Error: master/ directory is not configured or does not exist."
    warn "Add 'master: { path: master/ }' to targets.yaml and create the directory."
    exit 1
  end

  # -i already asks y/N for the picked files, so it goes on to execute without
  # --execute.
  def dry_run?
    !(options[:execute] || options[:interactive])
  end

  def confirm_and_execute(change_labels, dry_run, execute_command:)
    if change_labels.empty?
      puts "Nothing to do."
      return false
    end

    change_labels.each { |l| puts "  #{l}" }

    if dry_run
      puts "\n#{change_labels.size} file(s) would be changed."
      print_next_steps("execute these changes" => execute_command)
      return false
    end

    yes?("\nProceed with #{change_labels.size} change(s)? [y/N]")
  end

  # Each line carries the two paths its preview diffs, so moving the cursor
  # runs only git instead of starting this script again. The diff goes from
  # dest to src, so its "+" lines are what the change will write.
  def pick_changes(changes, header:)
    return changes if changes.empty?

    lines = changes.each_with_index.map do |change, i|
      [i, preview_path(change[:dest]), preview_path(change[:src]), change[:pick_label] || change[:label]].join("\t")
    end
    # Space picks instead of fzf's default Tab, which is awkward to reach on
    # some keyboards, and it only toggles without moving down, so the line
    # just picked stays in view. Space can no longer be typed into the query,
    # which matters little for paths. fzf's thin default marker is easy to
    # miss, so picked lines get a bold "+" and a dark green background (22:
    # the cursor line is gray and [conflict] labels are red). On the cursor
    # line fzf's own background wins, leaving the marker as the only sign.
    #
    # The preview sits beside the list at half width, and drops under it when
    # that half is narrower than the 80 columns code is usually wrapped at.
    # Under the list it takes 60% of the height, as a diff needs more lines
    # than the one-line entries do.
    out, status = Open3.capture2("fzf", "--multi", "--ansi", "--delimiter", "\t", "--with-nth", "4",
                                 "--bind", "space:toggle", "--marker", "+",
                                 "--color", "marker:green:bold,selected-bg:22",
                                 "--header", header, "--header-border", "line",
                                 "--header-label", " space: toggle / enter: confirm ",
                                 "--preview", "git diff --no-index --color=always -- {2} {3}",
                                 "--preview-label", " + lines get written ",
                                 "--preview-window", "right,50%,<80(down,60%)",
                                 stdin_data: lines.join("\n"))
    # Exit 1 (nothing toggled and no line matches the query) and 130 (Esc or
    # ctrl-c) pick nothing. Any other failure, such as an option this fzf does
    # not know, is reported instead of being passed off as an empty pick.
    return [] if [1, 130].include?(status.exitstatus)

    unless status.success?
      warn "Error: fzf failed (#{status})."
      exit 1
    end

    # fzf prints the picks in the order they were selected; sorting keeps the
    # confirmation in the order the changes were given to fzf.
    changes.values_at(*out.lines.map { it.split("\t").first.to_i }.sort)
  rescue Errno::ENOENT
    warn "Error: fzf is required for --interactive."
    exit 1
  end

  # git diff --no-index compares a symlink as the link itself and cannot open
  # a missing path, so the preview gets the file the link points to, or
  # /dev/null for a side that does not exist or cannot be resolved (e.g. a
  # dangling symlink), which git shows as added or deleted.
  def preview_path(path)
    File.realpath(path.to_s)
  rescue SystemCallError
    File::NULL
  end

  def print_next_steps(steps)
    print_steps_under("Next:", steps)
  end

  # For alternatives such as opposite sync directions, where only one of the
  # steps should be run. A separate method rather than a keyword option, since
  # a keyword would swallow the braceless "description" => "command" hashes.
  def print_next_choices(steps)
    print_steps_under(steps.size > 1 ? "Next (pick one):" : "Next:", steps)
  end

  # Prints each command on a line of its own under its description. A trailing
  # "# description" is avoided because zsh without interactive_comments passes
  # it through as arguments when the line is pasted.
  def print_steps_under(header, steps)
    return if steps.empty?

    puts "\n#{header}"
    steps.each do |description, command|
      puts "  #{description}:"
      puts "    #{command}"
    end
  end

  # The step that brings a clean env worktree level with its remote. Behind
  # wins over ahead: a diverged branch must pull before its push is accepted.
  def remote_sync_step(behind, ahead)
    if behind.positive?
      { "pull the branch" => "nukegara git pull" }
    elsif ahead.positive?
      { "push the branch" => "nukegara git push" }
    else
      {}
    end
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
  option :interactive, type: :boolean, default: false, aliases: "-i",
                       desc: "Pick files in fzf, then confirm and execute"
  def pull
    sync(direction: :pull)
  end

  desc "apply", "Apply env worktree -> local filesystem"
  option :execute, type: :boolean, default: false, desc: "Actually execute (default: dry-run)"
  option :interactive, type: :boolean, default: false, aliases: "-i",
                       desc: "Pick files in fzf, then confirm and execute"
  def apply
    sync(direction: :apply)
  end

  desc "status", "List files that differ between local filesystem and env worktree"
  def status
    entries = local_env_diff
    if entries.empty?
      puts "No differences found."
      return
    end

    entries.each { puts status_line(it) }
    print_next_steps("review a file's diff" => "nukegara local diff <path>")
  end

  desc "diff [NUKEGARA_REL]",
       "Show worktree -> local diffs of all differing files in a pager. With path: only that file"
  def diff(nukegara_rel = nil)
    entries = local_env_diff

    if nukegara_rel
      entry = entries.find { it[:nukegara_rel] == nukegara_rel }
      unless entry
        warn "Error: '#{nukegara_rel}' is not listed by `nukegara local status`."
        exit 1
      end
      shown = [entry]
    elsif entries.empty?
      puts "No differences found."
      return
    else
      shown = entries
    end

    show_diffs("worktree", "local", shown.map { [it[:nukegara_rel], it[:env_path], it[:local_path]] })
    print_next_choices(sync_choices(entries))
  end

  private

  def local_env_diff
    host_config = @config.current_host_config
    @config.check_worktree_exists!(host_config)
    LocalEnvDiff.compute(@config, host_config)
  end

  def status_line(entry)
    colorize("[#{entry[:kind].to_s.tr('_', '-')}] #{entry[:nukegara_rel]}", :yellow)
  end

  # pull copies only files that exist locally and apply only files that exist
  # in the worktree, so a one-sided diff leaves the other direction a no-op.
  def sync_choices(entries)
    kinds = entries.map { it[:kind] }
    choices = {}
    choices["sync local -> env"] = "nukegara local pull" if kinds.intersect?([:worktree_missing, :differ])
    choices["sync env -> local"] = "nukegara local apply" if kinds.intersect?([:local_missing, :differ])
    choices
  end

  # pull copies local -> worktree, apply copies worktree -> local. Both walk
  # the same target list and differ only in which side is the source.
  def sync(direction:)
    host_config = @config.current_host_config
    @config.check_worktree_exists!(host_config)

    worktree_dir = @config.worktree_dir(host_config)
    missing_kind = direction == :pull ? :worktree_missing : :local_missing
    changes = []

    host_config[:targets].each do |entry|
      local_base = File.expand_path(entry[:target])
      env_base   = worktree_dir.join(entry[:nukegara])
      src_base   = direction == :pull ? Pathname(local_base) : env_base

      collect_files(src_base, entry[:exclude]).each do |rel, src|
        dest_base = direction == :pull ? env_base : Pathname(local_base)
        dest = resolve(dest_base, rel)
        next if dest.file? && FileUtils.cmp(src.to_s, dest.to_s)

        pick_entry = { kind: dest.file? ? :differ : missing_kind,
                       nukegara_rel: Pathname(entry[:nukegara]).join(rel).cleanpath.to_s }
        changes << { src: src, dest: dest, pick_label: status_line(pick_entry) }
      end
    end

    if options[:interactive]
      sides = direction == :pull ? "local -> env" : "env -> local"
      changes = pick_changes(changes, header: "local #{direction}: #{sides}")
    end

    return unless confirm_and_execute(changes.map { "#{it[:src]} -> #{it[:dest]}" }, dry_run?,
                                      execute_command: "nukegara local #{direction} --execute")

    apply_changes(changes)
    puts "local #{direction} completed."
    # apply only writes to local, so the worktree has nothing new to commit.
    print_next_steps("stage the worktree changes" => "nukegara git stage") if direction == :pull
  end
end

class Master < Thor
  include NukegaraHelpers

  def initialize(*args)
    super
    @config = NukegaraConfig.new
  end

  desc "status", "List conflicting and env-only files between master and current env worktree"
  def status
    entries = effective_entries
    conflicts = differing_conflicts(entries)

    entries.select { it[:source] == :env }.each { puts env_only_line(it) }
    conflicts.each { puts conflict_line(it) }

    if conflicts.empty?
      puts "No conflicts found."
    else
      print_next_steps("review a conflict's diff" => "nukegara master diff <path>")
    end
  end

  desc "diff [NUKEGARA_REL]",
       "Show master -> env diffs of all conflicting files in a pager. With path: only that file"
  def diff(nukegara_rel = nil)
    conflicts = differing_conflicts(effective_entries)

    if nukegara_rel
      entry = conflicts.find { it[:nukegara_rel] == nukegara_rel }
      unless entry
        warn "Error: '#{nukegara_rel}' is not listed as a conflict by `nukegara master status`."
        exit 1
      end
      shown = [entry]
    elsif conflicts.empty?
      puts "No conflicts found."
      return
    else
      shown = conflicts
    end

    show_diffs("master", "env", shown.map { [it[:nukegara_rel], it[:master_path], it[:env_path]] })

    # When a path was given, only that file has been reviewed, so promote is
    # narrowed to it rather than overwriting conflicts never looked at. apply
    # takes no path, so it still covers every conflict.
    promote_command = ["nukegara master promote", nukegara_rel&.shellescape].compact.join(" ")
    print_next_choices(
      "promote env -> master" => promote_command,
      "apply master -> env" => "nukegara master apply"
    )
  end

  desc "promote [NUKEGARA_REL]",
       "Promote env to master. No args: dry-run all conflicts. With path: promote specific file (conflict or env-only)"
  option :execute, type: :boolean, default: false, desc: "Actually execute (default: dry-run)"
  option :interactive, type: :boolean, default: false, aliases: "-i",
                       desc: "Pick conflicts and env-only files in fzf, then confirm and execute"
  def promote(nukegara_rel = nil)
    if options[:interactive] && nukegara_rel
      warn "Error: give either a path or --interactive, not both."
      exit 1
    end

    require_master!(@config)
    host_config = @config.current_host_config
    @config.check_worktree_exists!(host_config)

    all_entries = EffectiveConfig.compute(@config, host_config)

    if options[:interactive]
      promote_picked(all_entries)
    elsif nukegara_rel.nil?
      promote_all(all_entries)
    else
      promote_one(all_entries, nukegara_rel)
    end
  end

  desc "apply", "Overwrite current env worktree to match master (overwrite conflicts)"
  option :execute, type: :boolean, default: false, desc: "Actually execute (default: dry-run)"
  option :interactive, type: :boolean, default: false, aliases: "-i",
                       desc: "Pick files in fzf, then confirm and execute"
  def apply
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

        changes << { src: src, dest: dest, label: conflict_line(entry) }
      when :master
        src  = entry[:master_path]
        dest = worktree.join(entry[:nukegara_rel])
        next if dest.file? && FileUtils.cmp(src.to_s, dest.to_s)

        changes << { src: src, dest: dest, label: "[master->env] #{entry[:nukegara_rel]}" }
      when :env
        # env-only files are left untouched; apply only flows master -> env.
      end
    end

    changes = pick_changes(changes, header: "master apply: master -> env") if options[:interactive]

    return unless confirm_and_execute(changes.map { |change| change[:label] }, dry_run?,
                                      execute_command: "nukegara master apply --execute")

    apply_changes(changes)
    puts "master apply completed."
    print_next_steps(
      "sync env -> local" => "nukegara local apply",
      "stage the worktree changes" => "nukegara git stage"
    )
  end

  private

  def effective_entries
    require_master!(@config)
    host_config = @config.current_host_config
    @config.check_worktree_exists!(host_config)
    EffectiveConfig.compute(@config, host_config)
  end

  def conflict_line(entry)
    colorize("[conflict] #{entry[:nukegara_rel]}", :red)
  end

  def env_only_line(entry)
    colorize("[env-only] #{entry[:nukegara_rel]}", :cyan)
  end

  # Promotes every conflicting file (env content wins) to master.
  def promote_all(all_entries)
    changes = all_entries.select { |e| e[:source] == :conflict }.filter_map do |e|
      next if FileUtils.cmp(e[:master_path].to_s, e[:env_path].to_s)

      { src: e[:env_path], dest: e[:master_path], label: conflict_line(e) }
    end

    return unless confirm_and_execute(changes.map { |change| change[:label] }, dry_run?,
                                      execute_command: "nukegara master promote --execute")

    apply_changes(changes)
    puts "master promote completed."
  end

  # Promotes a single file (conflict or env-only) to master.
  def promote_one(all_entries, nukegara_rel)
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

    return unless confirm_and_execute(["#{src} -> #{dest}"], dry_run?,
                                      execute_command: "nukegara master promote #{nukegara_rel.shellescape} --execute")

    apply_changes([{ src: src, dest: dest }])
    puts "master promote completed."
  end

  # Offers env-only files as well as conflicts, the same files promote_one
  # accepts, rather than only the conflicts promote_all covers.
  def promote_picked(all_entries)
    changes = all_entries.filter_map do |e|
      case e[:source]
      when :conflict
        # same_content? rather than FileUtils.cmp, so a dangling symlink shows
        # up in the list instead of aborting before fzf opens.
        next if PathCollector.same_content?(e[:master_path], e[:env_path])

        { src: e[:env_path], dest: e[:master_path], label: conflict_line(e) }
      when :env
        { src: e[:env_path], dest: @config.master_dir.join(e[:nukegara_rel]), label: env_only_line(e) }
      end
    end
    changes = pick_changes(changes, header: "master promote: env -> master")

    return unless confirm_and_execute(changes.map { |change| change[:label] }, dry_run?,
                                      execute_command: "nukegara master promote -i")

    apply_changes(changes)
    puts "master promote completed."
  end
end

# Wraps the git operations on the env worktree that the workflow would
# otherwise run by hand (cd worktree; git add/commit/push/pull). The branch and
# worktree path both come from targets.yaml, so no arguments are needed.
class Git < Thor
  include NukegaraHelpers
  include WorktreeGit

  def initialize(*args)
    super
    @config = NukegaraConfig.new
  end

  desc "status", "Show git status of the env worktree"
  def status
    host_config = @config.current_host_config
    @config.check_worktree_exists!(host_config)
    worktree = @config.worktree_dir(host_config)

    run_git(host_config, "status", "-sb")

    changes = worktree_changes(worktree)
    # A non-blank Y in "XY PATH" (the worktree column, "?" for untracked files)
    # means something is still unstaged; unmerged paths also land here, and
    # staging is how git marks them resolved.
    if changes.any? { |line| line[1] != " " }
      print_next_steps("stage the worktree changes" => "nukegara git stage")
    elsif changes.any?
      print_next_steps("commit the staged changes" => "nukegara git commit")
    else
      print_next_steps(remote_sync_step(*upstream_divergence(worktree)))
    end
  end

  desc "stage", "Stage all changes in the env worktree (git add -A)"
  def stage
    host_config = @config.current_host_config
    @config.check_worktree_exists!(host_config)

    dirty = run_git(host_config, "status", "--porcelain", capture: true)
    abort("Nothing to stage.") if dirty.strip.empty?

    run_git(host_config, "add", "-A")
    run_git(host_config, "status", "-sb")
    print_next_steps("commit the staged changes" => "nukegara git commit")
  end

  # Default commit message used when -m is omitted, matching the manual
  # workflow this helper replaces.
  DEFAULT_COMMIT_MESSAGE = "update dotfiles".freeze

  desc "commit", "Commit the staged changes in the env worktree"
  option :message, type: :string, aliases: "-m", desc: "Commit message (default: \"#{DEFAULT_COMMIT_MESSAGE}\")"
  def commit
    host_config = @config.current_host_config
    @config.check_worktree_exists!(host_config)

    abort("Nothing staged to commit. Run `nukegara git stage` first.") unless anything_staged?(host_config)

    message = options[:message] || DEFAULT_COMMIT_MESSAGE
    run_git(host_config, "commit", "-m", message)
    print_next_steps("push the branch" => "nukegara git push")
  end

  desc "push", "Push the env worktree branch to its remote"
  def push
    host_config = @config.current_host_config
    @config.check_worktree_exists!(host_config)

    run_git(host_config, "push")
  end

  desc "pull", "Pull the env worktree branch from its remote"
  def pull
    host_config = @config.current_host_config
    @config.check_worktree_exists!(host_config)

    run_git(host_config, "pull")
    print_next_steps("check the sync state" => "nukegara health")
  end

  desc "setup", "Create the env worktree for this host's configured branch"
  def setup
    host_config = @config.current_host_config
    branch = host_config[:branch]
    worktree = @config.worktree_dir(host_config)

    if worktree.directory?
      puts "Worktree already exists: #{worktree}"
    else
      # A worktree can only be added for a branch git already knows about. Create
      # and publish the branch first when neither the local nor the remote ref
      # exists yet, so a brand-new environment works from a single command.
      create_branch_if_missing(branch)

      git_in_root("worktree", "add", branch, branch)
      puts "Worktree created: #{worktree}"
    end

    print_next_steps("check the sync state" => "nukegara health")
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
  include WorktreeGit

  def initialize(*args)
    super
    @config = NukegaraConfig.new
  end

  desc "local SUBCOMMAND", "Manage local filesystem <-> env worktree"
  subcommand "local", Local

  desc "master SUBCOMMAND", "Manage master <-> env worktrees"
  subcommand "master", Master

  desc "git SUBCOMMAND", "Run git operations on the env worktree (status/stage/commit/push/pull/setup)"
  subcommand "git", Git

  desc "health",
       "Show a one-line diff summary across stages (local <-> env <-> master, env <-> remote) and what to run next"
  def health
    host_config = @config.current_host_config
    @config.check_worktree_exists!(host_config)

    local_env  = local_env_counts(host_config)
    env_master = env_master_counts(host_config) if @config.master_enabled?
    worktree   = @config.worktree_dir(host_config)
    fetched    = fetch_upstream(worktree)
    env_remote = env_remote_counts(worktree)

    env_master_summary = if env_master
                           format_stage("env<->master", env_master)
                         else
                           "env<->master skipped"
                         end
    env_remote_summary = format_stage("env<->remote", env_remote)
    env_remote_summary += " (fetch failed)" unless fetched
    puts "health: #{format_stage('local<->env', local_env)} / #{env_master_summary} / #{env_remote_summary}"

    # env<->remote comes first: syncing local against an env that is behind
    # its remote would build on stale files from before another machine's push.
    next_steps = if env_remote[:uncommitted].positive?
                   { "review env<->remote" => "nukegara git status" }
                 else
                   remote_sync_step(env_remote[:behind], env_remote[:ahead])
                 end
    next_steps["review local<->env"] = "nukegara local status" if local_env.values.sum.positive?
    next_steps["review env<->master"] = "nukegara master status" if env_master && env_master.values.sum.positive?
    print_next_steps(next_steps)
  end

  private

  # Counts how local and the env worktree diverge: files present on only one
  # side (missing) and files present on both but differing in content.
  def local_env_counts(host_config)
    LocalEnvDiff.compute(@config, host_config)
                .map { it[:kind] == :differ ? :differ : :missing }
                .tally
  end

  # Counts conflicts between master and the env worktree (files in both whose
  # content differs). env-only files are healthy (just not promoted yet) and
  # master-only files are not conflicts, so neither is counted.
  def env_master_counts(host_config)
    { conflict: differing_conflicts(EffectiveConfig.compute(@config, host_config)).size }
  end

  # Counts how the env worktree diverges from its remote: uncommitted files,
  # commits not yet pushed (ahead) and commits not yet pulled (behind).
  def env_remote_counts(worktree)
    behind, ahead = upstream_divergence(worktree)
    { uncommitted: worktree_changes(worktree).size, ahead: ahead, behind: behind }
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
