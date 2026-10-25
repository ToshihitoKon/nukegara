require_relative "nukegara_config"
require_relative "worktree_git"
require_relative "effective_config"
require_relative "local_env_diff"
require_relative "nukegara_helpers"
require_relative "commands/local"
require_relative "commands/master"
require_relative "commands/git"

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

    # env<->remote first, since syncing local against an env behind its remote
    # would build on stale files.
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

  def local_env_counts(host_config)
    LocalEnvDiff.compute(@config, host_config)
                .map { it[:kind] == :differ ? :differ : :missing }
                .tally
  end

  # env-only and master-only files are healthy, so only conflicts count.
  def env_master_counts(host_config)
    { conflict: differing_conflicts(EffectiveConfig.compute(@config, host_config)).size }
  end

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
