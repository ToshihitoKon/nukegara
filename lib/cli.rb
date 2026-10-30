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

  desc "git SUBCOMMAND", "Run git operations on the env worktree and master/ (status/stage/commit/push/pull/setup)"
  subcommand "git", Git

  desc "health",
       "Show a one-line diff summary across stages (local <-> env <-> master, env/master <-> remote) " \
       "and what to run next"
  def health
    host_config = @config.current_host_config
    @config.check_worktree_exists!(host_config)

    local_env  = local_env_counts(host_config)
    env_master = env_master_counts(host_config) if @config.master_enabled?
    # One fetch covers master too, as master/ lives in this same repository.
    fetched    = fetch_upstream(@config.worktree_dir(host_config))
    remotes    = @config.git_targets(host_config).to_h { [it[:name], remote_counts(it)] }

    env_master_summary = if env_master
                           format_stage("env<->master", env_master)
                         else
                           "env<->master skipped"
                         end
    remote_summaries = remotes.map do |name, counts|
      summary = format_stage("#{name}<->remote", counts)
      fetched ? summary : "#{summary} (fetch failed)"
    end
    puts "health: #{[format_stage('local<->env', local_env), env_master_summary, *remote_summaries].join(' / ')}"

    # Remote stages first, since syncing against an env or master behind its
    # remote would build on stale files.
    next_steps = if remotes.values.any? { it[:uncommitted].positive? }
                   { "review the uncommitted changes" => nukegara_command("git status") }
                 else
                   remote_sync_step(remotes.values.sum { it[:behind] }, remotes.values.sum { it[:ahead] })
                 end
    next_steps["review local<->env"] = nukegara_command("local status") if local_env.values.sum.positive?
    next_steps["review env<->master"] = nukegara_command("master status") if env_master && env_master.values.sum.positive?
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

  def remote_counts(target)
    behind, ahead = upstream_divergence(target[:dir], target[:pathspec])
    { uncommitted: worktree_changes(target[:dir], target[:pathspec]).size, ahead: ahead, behind: behind }
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
