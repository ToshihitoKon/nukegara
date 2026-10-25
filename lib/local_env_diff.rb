require_relative "path_collector"

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
