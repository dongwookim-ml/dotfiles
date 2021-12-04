" install vim-plug if not
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" load plug-ins, to install plugins run :PlugInstall
call plug#begin('~/.vim/plugged')
Plug 'vim-scripts/indentpython.vim'
"Plug 'tmhedberg/SimpylFold'
"Plug 'Valloric/YouCompleteMe'

" Plug 'vim-syntastic/syntastic'
" set statusline+=%#warningmsg#
" set statusline+=%{SyntasticStatuslineFlag()}
" set statusline+=%*

" let g:syntastic_always_populate_loc_list = 1
" let g:syntastic_auto_loc_list = 1
" let g:syntastic_check_on_open = 1
" let g:syntastic_check_on_wq = 0
" let g:syntastic_tex_checkers = ['synthastic-checkers-texinfo']

Plug 'nvie/vim-flake8'

Plug 'scrooloose/nerdtree'
"Ctrl-n for nerd tree toggle
nmap <C-n> :NERDTreeToggle<CR>
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

let NERDTreeIgnore=['\.pyc$', '\~$'] "ignore files in NERDTree

Plug 'tpope/vim-fugitive'

let python_highlight_all=1

Plug 'lervag/vimtex'
"Use MacVim app!
"let g:vimtex_compiler_latexmk = {'callback' : 0}
"Clean up when close tex file, compile on initialization
augroup vimtex_config
    au!
    au User VimtexEventQuit call vimtex#compiler#clean(0)
augroup END

"Comment lines with 'gc'
Plug 'tpope/vim-commentary'
nnoremap <C-c> :Commentary<CR>
vnoremap <C-c> :Commentary<CR>

call plug#end()

syntax on

set nu              " Set line number 

set tabstop=4       " The width of a TAB is set to 4.
                    " Still it is a \t. It is just that
                    " Vim will interpret it to be having
                    " a width of 4.
set shiftwidth=4    " Indents will have a width of 4
set softtabstop=4   " Sets the number of columns for a TAB
set expandtab       " Expand TABs to spaces
set smarttab        " Enabling this will make the tab key 
                    "(in insert mode) insert spaces or tabs 
                    "to go to the next indent of the next tabstop
                    "when the cursor is at the beginning of a line
                    "(ie: the only preceding characters are whitespace).

set splitbelow
set splitright

"work backspace as normal
set backspace=indent,eol,start

"disable swap file
set noswapfile

"set font
set guifont=Meslo\ LG\ S\ Regular\ for\ Powerline:h14

"set mouse enabled for normal mode
set mouse=n

"for clipboard sharing
set clipboard=unnamed

"split navigations
"Ctrl-j: move to the split below
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" Enable folding
"set foldmethod=indent
"set foldlevel=99

" Enable folding with the spacebar
"nnoremap <space> za

" Press F4 to toggle highlighting on/off, and show current value.
noremap <Space> :set hlsearch! hlsearch?<CR>

"Color scheme solarized: https://github.com/altercation/vim-colors-solarized
set background=dark
colorscheme solarized

set encoding=utf-8

" For powerline-status: https://github.com/powerline/powerline
set rtp+=/usr/local/anaconda3/lib/python3.6/site-packages/powerline/bindings/vim
" Always show statusline
set laststatus=2
" Use 256 colours (Use this setting only if your terminal supports 256 colours)
set t_Co=256

map <F10> :VimtexCompile<CR>
"map <F10> :execute '!pdflatex ' . shellescape(expand('%'), 1) . ' && open ' . shellescape(expand('%:r') . '.pdf', 1)<CR>

" Bind F5 to save file if modified and execute python script in a buffer.
nnoremap <silent> <F5> :call SaveAndExecutePython()<CR>
vnoremap <silent> <F5> :<C-u>call SaveAndExecutePython()<CR>

function! SaveAndExecutePython()
    " SOURCE [reusable window]: https://github.com/fatih/vim-go/blob/master/autoload/go/ui.vim

    " save and reload current file
    silent execute "update | edit"

    " get file path of current file
    let s:current_buffer_file_path = expand("%")

    let s:output_buffer_name = "Python"
    let s:output_buffer_filetype = "output"

    " reuse existing buffer window if it exists otherwise create a new one
    if !exists("s:buf_nr") || !bufexists(s:buf_nr)
        silent execute 'botright new ' . s:output_buffer_name
        let s:buf_nr = bufnr('%')
    elseif bufwinnr(s:buf_nr) == -1
        silent execute 'botright new'
        silent execute s:buf_nr . 'buffer'
    elseif bufwinnr(s:buf_nr) != bufwinnr('%')
        silent execute bufwinnr(s:buf_nr) . 'wincmd w'
    endif

    silent execute "setlocal filetype=" . s:output_buffer_filetype
    setlocal bufhidden=delete
    setlocal buftype=nofile
    setlocal noswapfile
    setlocal nobuflisted
    setlocal winfixheight
    setlocal cursorline " make it easy to distinguish
    setlocal nonumber
    setlocal norelativenumber
    setlocal showbreak=""

    " clear the buffer
    setlocal noreadonly
    setlocal modifiable
    %delete _

    " add the console output
    silent execute ".!python " . shellescape(s:current_buffer_file_path, 1)

    " resize window to content length
    " Note: This is annoying because if you print a lot of lines then your code buffer is forced to a height of one line every time you run this function.
    "       However without this line the buffer starts off as a default size and if you resize the buffer then it keeps that custom size after repeated runs of this function.
    "       But if you close the output buffer then it returns to using the default size when its recreated
    "execute 'resize' . line('$')

    " make the buffer non modifiable
    setlocal readonly
    setlocal nomodifiable
endfunction

