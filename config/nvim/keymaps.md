# Neovim Keymap List

## Leader Key

- `<Leader>` - `\` (Default)

## Custom Keymaps (keymap.lua)

### File Explorer
- `<C-t>` (n) - Neotree toggle

### Window Navigation
- `<C-h>` (n) - Move to left window
- `<C-j>` (n) - Move to down window
- `<C-k>` (n) - Move to up window
- `<C-l>` (n) - Move to right window

### Search / Highlight
- `;` (n) - Start search (alias for `/`)
- `<C-c><C-c>` (n) - Clear search highlight

### LSP
- `<Space>` (n) - Show hover information

### Buffer Operations
- `<C-b><C-b>` (n) - Telescope buffer list
- `<C-b><C-q>` (n) - Close current buffer
- `<C-b><C-a>` (n) - Close all buffers
- `<` (n) - Switch to previous buffer

---

## Plugin Keymaps

### Claude Code
- `<C-\>` (n) - Claude Code: Toggle
- `<Leader>cC` (n) - Claude Code: Continue
- `<Leader>cV` (n) - Claude Code: Verbose

### Terminal
- `<C-f>` (n) - Toggle terminal (ToggleTerm)

### Window Resize
- `<C-e>` (n) - Start WinResizer

### Scroll (neoscroll)
- `<C-d>` (n/s/x) - Scroll down
- `<C-u>` (n/s/x) - Scroll up

### Git
- `<Leader>gy` (n/v) - Get git URL for current line (gitlinker)

### Emmet
- `<C-y>,` (n/v) - Expand abbreviation
- `<C-y>;` (n) - Expand word
- `<C-y>u` (n) - Update tag
- `<C-y>d` (n/v) - Balance tag inward
- `<C-y>D` (n/v) - Balance tag outward
- `<C-y>n` (n) - Move to next edit point
- `<C-y>N` (n) - Move to previous edit point
- `<C-y>i` (n) - Update image size
- `<C-y>I` (n) - Image encode
- `<C-y>/` (n) - Toggle comment
- `<C-y>j` (n) - Split/join tag
- `<C-y>k` (n) - Remove tag
- `<C-y>a` (n) - Anchorize URL
- `<C-y>A` (n) - Anchorize summary
- `<C-y>m` (n) - Merge lines
- `<C-y>c` (v) - Code pretty

---

## Default Keymaps (vim/_defaults.lua)

### LSP
- `grn` (n) - Rename symbol
- `gra` (n/x) - Code action
- `grr` (n) - Show references
- `gri` (n) - Go to implementation
- `grt` (n) - Go to type definition
- `gO` (n) - Document symbol
- `<C-s>` (s) - Signature help
- `<C-w>d` / `<C-w><C-d>` (n) - Show diagnostics under cursor

### Diagnostics
- `[d` (n) - Jump to previous diagnostic
- `]d` (n) - Jump to next diagnostic
- `[D` (n) - Jump to first diagnostic in buffer
- `]D` (n) - Jump to last diagnostic in buffer

### Quickfix List
- `[q` (n) - Previous quickfix item (`:cprevious`)
- `]q` (n) - Next quickfix item (`:cnext`)
- `[Q` (n) - First quickfix item (`:crewind`)
- `]Q` (n) - Last quickfix item (`:clast`)
- `[<C-q>` (n) - Previous quickfix file (`:cpfile`)
- `]<C-q>` (n) - Next quickfix file (`:cnfile`)

### Location List
- `[l` (n) - Previous location (`:lprevious`)
- `]l` (n) - Next location (`:lnext`)
- `[L` (n) - First location (`:lrewind`)
- `]L` (n) - Last location (`:llast`)
- `[<C-l>` (n) - Previous location file (`:lpfile`)
- `]<C-l>` (n) - Next location file (`:lnfile`)

### Buffer Navigation
- `[b` (n) - Previous buffer (`:bprevious`)
- `]b` (n) - Next buffer (`:bnext`)
- `[B` (n) - First buffer (`:brewind`)
- `]B` (n) - Last buffer (`:blast`)

### Argument List
- `[a` (n) - Previous argument (`:previous`)
- `]a` (n) - Next argument (`:next`)
- `[A` (n) - First argument (`:rewind`)
- `]A` (n) - Last argument (`:last`)

### Tag Navigation
- `[t` (n) - Previous tag (`:tprevious`)
- `]t` (n) - Next tag (`:tnext`)
- `[T` (n) - First tag (`:trewind`)
- `]T` (n) - Last tag (`:tlast`)
- `[<C-t>` (n) - Previous preview tag (`:ptprevious`)
- `]<C-t>` (n) - Next preview tag (`:ptnext`)

### Comment
- `gc` (n/x) - Toggle comment (operator)
- `gcc` (n) - Toggle comment for current line
- `gc` (o) - Comment text object
- `ic` (o/x) - Inner comment text object

### Editing
- `Y` (n) - Yank to end of line (`y$`)
- `&` (n) - Repeat last substitute (`:&&`)
- `[<Space>` (n) - Add empty line above cursor
- `]<Space>` (n) - Add empty line below cursor

### Search (Visual Mode)
- `*` (x) - Search forward for selected text
- `#` (x) - Search backward for selected text

### Misc
- `gx` (n/x) - Open filepath or URI under cursor with system handler
- `@` (x) - Execute macro in visual mode
- `Q` (x) - Execute recorded macro in visual mode

### Snippet
- `<Tab>` (s) - Jump to next snippet placeholder
- `<S-Tab>` (s) - Jump to previous snippet placeholder

---

## Matchit Plugin

- `%` (n/x/o) - Jump to matching bracket/tag
- `g%` (n/x/o) - Jump to matching bracket/tag (backward)
- `[%` (n/x/o) - Jump to previous unmatched group
- `]%` (n/x/o) - Jump to next unmatched group
- `a%` (x) - Select matching group (text object)

---

## Internal Mappings (<Plug>)

These are internal mappings called by other keymaps:

- `<Plug>(MatchitNormalForward)` - Matchit forward
- `<Plug>(MatchitNormalBackward)` - Matchit backward
- `<Plug>(MatchitVisualForward)` - Matchit visual forward
- `<Plug>(MatchitVisualBackward)` - Matchit visual backward
- `<Plug>(MatchitOperationForward)` - Matchit operator forward
- `<Plug>(MatchitOperationBackward)` - Matchit operator backward
- `<Plug>(MatchitNormalMultiForward)` - Matchit multi forward
- `<Plug>(MatchitNormalMultiBackward)` - Matchit multi backward
- `<Plug>(MatchitVisualMultiForward)` - Matchit visual multi forward
- `<Plug>(MatchitVisualMultiBackward)` - Matchit visual multi backward
- `<Plug>(MatchitOperationMultiForward)` - Matchit operation multi forward
- `<Plug>(MatchitOperationMultiBackward)` - Matchit operation multi backward
- `<Plug>(MatchitVisualTextObject)` - Matchit text object
- `<Plug>(emmet-expand-abbr)` - Emmet expand abbreviation
- `<Plug>(emmet-expand-word)` - Emmet expand word
- `<Plug>(emmet-update-tag)` - Emmet update tag
- `<Plug>(emmet-balance-tag-inward)` - Emmet balance tag inward
- `<Plug>(emmet-balance-tag-outword)` - Emmet balance tag outward
- `<Plug>(emmet-move-next)` - Emmet move next
- `<Plug>(emmet-move-prev)` - Emmet move prev
- `<Plug>(emmet-move-next-item)` - Emmet move next item
- `<Plug>(emmet-move-prev-item)` - Emmet move prev item
- `<Plug>(emmet-image-size)` - Emmet image size
- `<Plug>(emmet-image-encode)` - Emmet image encode
- `<Plug>(emmet-toggle-comment)` - Emmet toggle comment
- `<Plug>(emmet-split-join-tag)` - Emmet split join tag
- `<Plug>(emmet-remove-tag)` - Emmet remove tag
- `<Plug>(emmet-anchorize-url)` - Emmet anchorize URL
- `<Plug>(emmet-anchorize-summary)` - Emmet anchorize summary
- `<Plug>(emmet-merge-lines)` - Emmet merge lines
- `<Plug>(emmet-code-pretty)` - Emmet code pretty
- `<Plug>PlenaryTestFile` - Run plenary test for current file

---

## Mode Legend

- `n` - Normal mode
- `v` - Visual mode
- `x` - Visual mode (characterwise)
- `s` - Select mode
- `o` - Operator-pending mode
- `i` - Insert mode
- `t` - Terminal mode
