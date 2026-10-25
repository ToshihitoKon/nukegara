class NukegaraConfig
  attr_reader :hosts

  def initialize(yaml_path = ROOT_DIR.join("targets.yaml"))
    raw = YAML.load(File.read(yaml_path.to_s), symbolize_names: true)
    @master_path = raw.dig(:master, :path)
    @hosts = raw[:hosts]
  end

  def master_enabled?
    !@master_path.nil? && master_dir_path.directory?
  end

  def master_dir
    master_dir_path if master_enabled?
  end

  def current_host_config
    md5 = host_md5
    matched_hosts = @hosts.select { it[:md5] == md5 }
    if matched_hosts.size != 1
      warn "Error: Expected exactly one host configuration for this machine."
      warn "MD5: #{md5}"
      exit 1
    end
    matched_hosts.first
  end

  def worktree_dir(host_config)
    ROOT_DIR.join(host_config[:branch])
  end

  def check_worktree_exists!(host_config)
    return if worktree_dir(host_config).directory?

    warn "Error: Git worktree for branch #{host_config[:branch]} does not exist."
    warn "Please create worktree: git worktree add #{host_config[:branch]} #{host_config[:branch]}"
    exit 1
  end

  private

  # Pathname#join keeps an absolute master_path as-is.
  def master_dir_path
    ROOT_DIR.join(@master_path)
  end

  def host_md5
    hostname = `uname -n`.strip
    Digest::MD5.hexdigest(hostname)
  end
end
