require_relative "../nukegara_config"
require_relative "../path_collector"
require_relative "../effective_config"
require_relative "../nukegara_helpers"

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

    # Narrowed to the given path, so promote does not overwrite conflicts never
    # reviewed. apply takes no path.
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

  # Offers env-only files too, as promote_one does, not only conflicts.
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
