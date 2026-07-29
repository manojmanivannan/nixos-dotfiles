{ pkgs, ... }:

{
  # Declarative Vim config. Home Manager's `programs.vim` generates
  # `~/.vimrc` from `settings`/`extraConfig` and installs the plugins listed
  # below, so the editor is fully described here — no hand-managed vimrc.
  #
  # `settings` only accepts a fixed set of options (see the HM vim module);
  # everything else is emitted as raw `set` lines in `extraConfig`.
  programs.vim = {
    enable = true;

    settings = {
      # Line numbers: absolute + relative (current line shows its real number).
      number = true;
      relativenumber = true;

      # Tabs / indentation: spaces instead of tabs, 4-wide.
      expandtab = true;
      tabstop = 4;
      shiftwidth = 4;

      # Search: case-insensitive unless a capital is typed.
      ignorecase = true;
      smartcase = true;

      hidden = true;     # allow switching buffers without saving
      mouse = "a";       # mouse support in all modes
      undofile = true;   # persist undo history across sessions
    };

    extraConfig = ''
      " --- Indentation & editing behavior (not expressible via `settings`) ---
      set softtabstop=4
      set autoindent
      set smartindent
      set backspace=indent,eol,start
      set encoding=utf-8
      set clipboard=unnamedplus  " yank/paste to the system clipboard

      " --- Search ---
      set hlsearch
      set incsearch

      " --- Splitting: new windows open to the right and below ---
      set splitright
      set splitbelow

      " --- UI niceties ---
      set termguicolors         " 24-bit colors in supporting terminals
      set cursorline            " highlight the line under the cursor
      set wildmenu              " richer command-line completion menu
      set showmatch             " briefly jump to matching bracket
      set showcmd               " show incomplete command keystrokes
      set laststatus=2          " always show a statusline
      set signcolumn=yes        " keep the sign column open (no jump on lint signs)
      set scrolloff=8           " keep 8 lines of context above/below the cursor
      set sidescrolloff=8
      set updatetime=100        " faster swap write / CursorHold triggers

      " --- Persistence: keep swap/undo files tidy ---
      set nobackup
      set nowritebackup
      set noswapfile

      " Leader -> Space (set before plugins that depend on <leader>).
      let mapleader = " "

      " Turn off search highlight with <leader>/ until the next search.
      nnoremap <leader>/ :nohlsearch<CR>

      " Easier split navigation: <leader>{h,j,k,l} instead of <C-w>{...}.
      nnoremap <leader>h <C-w>h
      nnoremap <leader>j <C-w>j
      nnoremap <leader>k <C-w>k
      nnoremap <leader>l <C-w>l

      " Sensible default: Y behaves like C/D (to end of line), not like yy.
      nnoremap Y y$

      " Keep visual selection when re-indenting / shifting.
      vnoremap < <gv
      vnoremap > >gv

      " A minimal, informative statusline — no extra plugin required.
      set statusline=%f       " file path (relative)
      set statusline+=%m     " modified flag [+/-]
      set statusline+=%r     " readonly flag
      set statusline+=%y     " filetype in [brackets]
      set statusline+=%=     " left/right separator
      set statusline+=%{&fileencoding?&fileencoding:&encoding}
      set statusline+=\ %-7.(%l:%c%)   " cursor line:col
      set statusline+=\ %P   " percentage through file

      " Filetype + plugin handling.
      syntax enable
      filetype plugin indent on

      " Strip trailing whitespace on write (preserves cursor position).
      function! StripTrailingWhitespace()
        if &ft =~ 'markdown\|diff'
          return
        endif
        let l:save = winsaveview()
        keeppatterns %s/\s\+$//e
        call winrestview(l:save)
      endfunction
      autocmd BufWritePre * call StripTrailingWhitespace()
    '';

    # `vim-sensible` is force-added by the HM vim module, so it's not listed
    # here (listing it would duplicate it in the runtime path).
    plugins = with pkgs.vimPlugins; [
      vim-commentary        # gcc / gc to toggle comments
      vim-surround          # cs/ds/ys to edit surrounding pairs
      vim-repeat            # make plugin mappings repeatable with .
      vim-fugitive          # Git integration (:G, :Gblame, ...)
      vim-gitgutter         # +/-/~ signs in the sign column for git hunks
      supertab              # Tab to complete with <CR> feel
      nerdtree              # file explorer, :NERDTreeToggle
      nerdtree-git-plugin   # show git status flags in NERDTree
      vim-airline           # enhanced statusline/tabline
      vim-airline-themes    # airline color themes
      fzf-vim               # fuzzy file/buffer finder (uses fzf from fzf.nix)
    ];
  };
}