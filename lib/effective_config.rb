require_relative "path_collector"

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
