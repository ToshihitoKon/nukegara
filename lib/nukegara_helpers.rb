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
      # A missing or unreadable file counts as differing.
    end

    out, = Open3.capture2("diff", "--unified=3",
                          "--label", "#{left_label}/#{label}",
                          "--label", "#{right_label}/#{label}",
                          path_a.to_s, path_b.to_s)
    puts out unless out.empty?
    true
  end

  # One git diff over copies: per-file runs would open a pager per file, and
  # the real paths would diff a symlink as the link instead of its content.
  def show_diffs(left_label, right_label, files)
    Dir.mktmpdir("nukegara-diff") do |dir|
      # git refuses a missing directory, even when one side has no files.
      FileUtils.mkdir_p([File.join(dir, left_label), File.join(dir, right_label)])
      files.each do |rel, left_path, right_path|
        copy_for_diff(left_path, File.join(dir, left_label, rel))
        copy_for_diff(right_path, File.join(dir, right_label, rel))
      end

      # --no-renames keeps a one-sided file from pairing with a similar one.
      system("git", "-C", dir, "diff", "--no-index", "--no-prefix", "--no-renames", "--",
             left_label, right_label)
    end
  end

  # Not FileUtils.cp, which would carry the mode over into the diff.
  def copy_for_diff(src, dest)
    return if src.nil? || !File.readable?(src)

    FileUtils.mkdir_p(File.dirname(dest))
    IO.copy_stream(src.to_s, dest)
  end

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

  # -i asks y/N itself, so it needs no --execute.
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

  # Each line carries its preview's paths, so the preview runs only git, not
  # this script. dest comes first, so "+" lines are what gets written.
  def pick_changes(changes, header:)
    return changes if changes.empty?

    lines = changes.each_with_index.map do |change, i|
      [i, preview_path(change[:dest]), preview_path(change[:src]), change[:pick_label] || change[:label]].join("\t")
    end
    # space instead of Tab (hard to reach on some keyboards), and it toggles
    # without moving down. selected-bg 22 (dark green) stands apart from the
    # gray cursor line and red [conflict] labels. The preview goes under the
    # list when half the width is below 80 columns, taking 60% of the height
    # since a diff is taller than the one-line entries.
    out, status = Open3.capture2("fzf", "--multi", "--ansi", "--delimiter", "\t", "--with-nth", "4",
                                 "--bind", "space:toggle", "--marker", "+",
                                 "--color", "marker:green:bold,selected-bg:22",
                                 "--header", header, "--header-border", "line",
                                 "--header-label", " space: toggle / enter: confirm ",
                                 "--preview", "git diff --no-index --color=always -- {2} {3}",
                                 "--preview-label", " + lines get written ",
                                 "--preview-window", "right,50%,<80(down,60%)",
                                 stdin_data: lines.join("\n"))
    # 1: no match, 130: Esc or ctrl-c. Anything else (e.g. an unknown option)
    # is an error, not an empty pick.
    return [] if [1, 130].include?(status.exitstatus)

    unless status.success?
      warn "Error: fzf failed (#{status})."
      exit 1
    end

    # fzf prints picks in selection order; sort back to the given order.
    changes.values_at(*out.lines.map { it.split("\t").first.to_i }.sort)
  rescue Errno::ENOENT
    warn "Error: fzf is required for --interactive."
    exit 1
  end

  # git diff --no-index compares a symlink as the link and cannot open a
  # missing path; /dev/null shows that side as added or deleted.
  def preview_path(path)
    File.realpath(path.to_s)
  rescue SystemCallError
    File::NULL
  end

  # The script as it was run (e.g. ./nukegara.rb), not a bare "nukegara" that
  # would need a symlink on PATH.
  def nukegara_command(args)
    "#{$PROGRAM_NAME.shellescape} #{args}"
  end

  def print_next_steps(steps)
    print_steps_under("Next:", steps)
  end

  # A separate method rather than a keyword option, since a keyword would
  # swallow the braceless "description" => "command" hashes.
  def print_next_choices(steps)
    print_steps_under(steps.size > 1 ? "Next (pick one):" : "Next:", steps)
  end

  # No trailing "# description": zsh without interactive_comments passes it
  # as arguments when the line is pasted.
  def print_steps_under(header, steps)
    return if steps.empty?

    puts "\n#{header}"
    steps.each do |description, command|
      puts "  #{description}:"
      puts "    #{command}"
    end
  end

  # Behind wins over ahead: a diverged branch must pull before it can push.
  def remote_sync_step(behind, ahead)
    if behind.positive?
      { "pull from the remote" => nukegara_command("git pull") }
    elsif ahead.positive?
      { "push to the remote" => nukegara_command("git push") }
    else
      {}
    end
  end

  def apply_changes(changes)
    changes.each do |change|
      FileUtils.mkdir_p(change[:dest].dirname)
      FileUtils.copy(change[:src].to_s, change[:dest].to_s)
    end
  end
end
