module WorktreeGit
  module_function

  def worktree_changes(dir, pathspec = [])
    out, = Open3.capture2("git", "-C", dir.to_s, "status", "--porcelain", "--", *pathspec)
    out.lines
  end

  # [behind, ahead], as rev-list counts the left side first. A branch without
  # an upstream fails here; its stderr is dropped and it counts as [0, 0].
  def upstream_divergence(dir, pathspec = [])
    out, exit_status = Open3.capture2("git", "-C", dir.to_s,
                                      "rev-list", "--left-right", "--count", "@{upstream}...HEAD",
                                      "--", *pathspec, err: File::NULL)
    return [0, 0] unless exit_status.success?

    out.split.map(&:to_i)
  end

  # stderr is dropped since health reports a failed fetch itself.
  def fetch_upstream(worktree)
    system("git", "-C", worktree.to_s, "fetch", "--quiet", err: File::NULL)
  end
end
