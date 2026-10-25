module PathCollector
  module_function

  def collect_files(base_path, exclude = nil)
    return {} if base_path.nil? || !base_path.exist?

    if base_path.file?
      { "." => base_path }
    else
      base_path.glob("**/*")
               .reject(&:directory?)
               .each_with_object({}) do |path, files|
                 rel = path.relative_path_from(base_path).to_s
                 next if excluded?(rel, exclude)

                 files[rel] = path
               end
    end
  end

  # FNM_PATHNAME keeps `*` from crossing `/`; `**/*.log` reaches subdirectories.
  def excluded?(rel, exclude)
    return false if exclude.nil? || exclude.empty?

    exclude.any? { |pattern| File.fnmatch?(pattern, rel, File::FNM_PATHNAME | File::FNM_EXTGLOB) }
  end

  def resolve(base, rel)
    rel == "." ? Pathname(base) : Pathname(base).join(rel)
  end

  # A file that cannot be read (e.g. a dangling symlink) counts as differing,
  # so one broken file does not abort the whole listing.
  def same_content?(path_a, path_b)
    FileUtils.cmp(path_a.to_s, path_b.to_s)
  rescue SystemCallError
    false
  end
end
