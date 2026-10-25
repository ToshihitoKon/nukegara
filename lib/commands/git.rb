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

  desc "status", "Show git status of the env worktree"
  def status
    host_config = @config.current_host_config
    @config.check_worktree_exists!(host_config)
    worktree = @config.worktree_dir(host_config)

    run_git(host_config, "status", "-sb")

    changes = worktree_changes(worktree)
    # line[1] is the worktree column of "XY PATH" ("?" if untracked).
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

  # Matches the message of the manual workflow this command replaced.
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
      # git worktree add needs a branch git already knows.
      create_branch_if_missing(branch)

      git_in_root("worktree", "add", branch, branch)
      puts "Worktree created: #{worktree}"
    end

    print_next_steps("check the sync state" => "nukegara health")
  end

  private

  def run_git(host_config, *git_args, capture: false)
    worktree = @config.worktree_dir(host_config)

    if capture
      out, = Open3.capture2("git", "-C", worktree.to_s, *git_args)
      return out
    end

    system("git", "-C", worktree.to_s, *git_args) || abort("git #{git_args.first} failed.")
  end

  # --quiet exits 1 when something is staged.
  def anything_staged?(host_config)
    worktree = @config.worktree_dir(host_config)
    !system("git", "-C", worktree.to_s, "diff", "--cached", "--quiet")
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
