# Collects the files under a base path into a Hash keyed by path relative to
# the base. A single regular file is keyed as ".". The single source of truth
# for how files are enumerated, so every command sees the same set.
#
# exclude is an optional list of glob patterns (File.fnmatch syntax, matched
# against the base-relative path). Matching files are dropped from the result,
# so every command consistently skips them (e.g. log files under config dirs).
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

  # A path is excluded when it matches any glob pattern. FNM_PATHNAME keeps
  # `*` from crossing `/`, so `*.log` matches only top-level files while
  # `**/*.log` reaches into subdirectories.
  def excluded?(rel, exclude)
    return false if exclude.nil? || exclude.empty?

    exclude.any? { |pattern| File.fnmatch?(pattern, rel, File::FNM_PATHNAME | File::FNM_EXTGLOB) }
  end

  # Resolves a relative key from collect_files back to a real path under base.
  # A "." key means base itself was a single file, so base is returned as-is.
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
