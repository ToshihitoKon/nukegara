require_relative "../nukegara_config"
require_relative "../worktree_git"
require_relative "../nukegara_helpers"

class Git < Thor
  include NukegaraHelpers
  include WorktreeGit

  def initialize(*args)
    super
    @config = NukegaraConfig.new
  end

  desc "status", "Show git status of the env worktree and master/"
  def status
    targets = git_targets
    targets.each do |target|
      print_target_header(target)
      run_git(target, "status", "-sb", "--", *target[:pathspec])
    end

    changes = targets.flat_map { worktree_changes(it[:dir], it[:pathspec]) }
    # line[1] is the worktree column of "XY PATH" ("?" if untracked).
    if changes.any? { |line| line[1] != " " }
      print_next_steps("stage the changes" => nukegara_command("git stage"))
    elsif changes.any?
      print_next_steps("commit the staged changes" => nukegara_command("git commit"))
    else
      divergences = targets.map { upstream_divergence(it[:dir], it[:pathspec]) }
      print_next_steps(remote_sync_step(divergences.sum(&:first), divergences.sum(&:last)))
    end
  end

  desc "stage", "Stage all changes in the env worktree and master/ (git add -A)"
  def stage
    dirty_targets = git_targets.select { worktree_changes(it[:dir], it[:pathspec]).any? }
    abort("Nothing to stage.") if dirty_targets.empty?

    dirty_targets.each do |target|
      run_git(target, "add", "-A", "--", *target[:pathspec])
      print_target_header(target)
      run_git(target, "status", "-sb", "--", *target[:pathspec])
    end
    print_next_steps("commit the staged changes" => nukegara_command("git commit"))
  end

  # Matches the message of the manual workflow this command replaced.
  DEFAULT_COMMIT_MESSAGE = "update dotfiles".freeze

  desc "commit", "Commit the staged changes in the env worktree and master/"
  option :message, type: :string, aliases: "-m", desc: "Commit message (default: \"#{DEFAULT_COMMIT_MESSAGE}\")"
  def commit
    staged_targets = git_targets.select { anything_staged?(it) }
    abort("Nothing staged to commit. Run `#{nukegara_command('git stage')}` first.") if staged_targets.empty?

    message = options[:message] || DEFAULT_COMMIT_MESSAGE
    staged_targets.each do |target|
      print_target_header(target)
      # The pathspec keeps changes staged outside master/ (e.g. lib/) out of
      # master's commit.
      run_git(target, "commit", "-m", message, "--", *target[:pathspec])
    end
    print_next_steps("push to the remote" => nukegara_command("git push"))
  end

  desc "push", "Push the branches of the env worktree and master/ to their remotes"
  def push
    git_targets.each do |target|
      print_target_header(target)
      run_git(target, "push")
    end
  end

  desc "pull", "Pull the branches of the env worktree and master/ from their remotes"
  def pull
    git_targets.each do |target|
      print_target_header(target)
      run_git(target, "pull")
    end
    print_next_steps("check the sync state" => nukegara_command("health"))
  end

  desc "setup", "Create the env worktree for this host's configured branch"
  def setup
    host_config = @config.current_host_config
    branch = host_config[:branch]
    worktree = @config.worktree_dir(host_config)

    if worktree.directory?
      puts "Worktree already exists: #{worktree}"
    else
      # git worktree add needs a branch git already knows.
      create_branch_if_missing(branch)

      git_in_root("worktree", "add", branch, branch)
      puts "Worktree created: #{worktree}"
    end

    print_next_steps("check the sync state" => nukegara_command("health"))
  end

  private

  def git_targets
    host_config = @config.current_host_config
    @config.check_worktree_exists!(host_config)
    @config.git_targets(host_config)
  end

  # master/ prints the same relative paths as the env, so each output needs
  # its side named.
  def print_target_header(target)
    puts colorize("#{target[:name]}:", :cyan)
  end

  def run_git(target, *git_args)
    system("git", "-C", target[:dir].to_s, *git_args) || abort("git #{git_args.first} failed in #{target[:name]}.")
  end

  # --quiet exits 1 when something is staged.
  def anything_staged?(target)
    !system("git", "-C", target[:dir].to_s, "diff", "--cached", "--quiet", "--", *target[:pathspec])
  end

  def git_in_root(*git_args)
    system("git", "-C", ROOT_DIR.to_s, *git_args) || abort("git #{git_args.first} failed.")
  end

  def create_branch_if_missing(branch)
    return if branch_known?(branch)

    git_in_root("branch", branch)
    git_in_root("push", "-u", "origin", branch)
  end

  def branch_known?(branch)
    local, = Open3.capture2("git", "-C", ROOT_DIR.to_s,
                            "rev-parse", "--verify", "--quiet", branch)
    return true unless local.strip.empty?

    remote, = Open3.capture2("git", "-C", ROOT_DIR.to_s,
                             "ls-remote", "--heads", "origin", branch)
    !remote.strip.empty?
  end
end
