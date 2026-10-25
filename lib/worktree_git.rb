# Read-only git queries on the env worktree, shared by `git status` and
# `health` so both judge the worktree the same way.
module WorktreeGit
  module_function

  # Porcelain v1 lines ("XY PATH"), one per changed or untracked file.
  def worktree_changes(worktree)
    out, = Open3.capture2("git", "-C", worktree.to_s, "status", "--porcelain")
    out.lines
  end

  # Returns [behind, ahead] commit counts against the upstream's
  # remote-tracking ref, matching the [ahead N, behind M] of `status -sb`.
  # A branch without an upstream makes rev-list fail; that counts as [0, 0]
  # and its stderr is dropped so the caller's output stays clean.
  def upstream_divergence(worktree)
    out, exit_status = Open3.capture2("git", "-C", worktree.to_s,
                                      "rev-list", "--left-right", "--count", "@{upstream}...HEAD",
                                      err: File::NULL)
    return [0, 0] unless exit_status.success?

    out.split.map(&:to_i)
  end

  # Updates the remote-tracking ref so upstream_divergence sees pushes made
  # from other machines. stderr is dropped because the caller reports a
  # failure (e.g. offline) itself.
  def fetch_upstream(worktree)
    system("git", "-C", worktree.to_s, "fetch", "--quiet", err: File::NULL)
  end
end
