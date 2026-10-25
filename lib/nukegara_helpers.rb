require_relative "path_collector"

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
