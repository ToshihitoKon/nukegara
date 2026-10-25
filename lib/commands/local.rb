require_relative "../nukegara_config"
require_relative "../path_collector"
require_relative "../local_env_diff"
require_relative "../nukegara_helpers"

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
