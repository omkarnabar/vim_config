" auto-install vim-plug
if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  "autocmd VimEnter * PlugInstall
  "autocmd VimEnter * PlugInstall | source $MYVIMRC
endif
set splitright
set splitbelow
set tabstop=4 
set softtabstop=4 
set shiftwidth=4
set nowrap
set smartindent
set noswapfile

call plug#begin('~/.config/nvim/autoload/plugged')
Plug 'tpope/vim-surround'
Plug 'morhetz/gruvbox'
 Plug 'itchyny/lightline.vim'
" Better Syntax Support
    Plug 'sheerun/vim-polyglot'
    " File Explorer
    Plug 'scrooloose/NERDTree'
    " Auto pairs for '(' '[' '{'
    Plug 'jiangmiao/auto-pairs'
    Plug 'ghifarit53/tokyonight-vim'
    " Using Vim-Plug
Plug 'navarasu/onedark.nvim'
call plug#end()
set termguicolors
let g:onedark_config = {
    \ 'style': 'deep',
\}
let g:lightline = {
      \ 'colorscheme': 'wombat',
      \ }
"let g:tokyonight_style = "storm" available: night, storm
"let g:tokyonight_enable_italic = 1
"colorscheme gruvbox
"colorscheme tokyonight
let g:mapleader=" "

nnoremap <leader>co :call IOBufferSetup()<cr>
nnoremap <leader>cc :call CloseIOBuffers()<cr>
nnoremap <leader>cr :call CompileAndRun()<cr>

colorscheme onedark
command! Config :lua find_configs()

" setup input/output buffers on the right side for python,cpp,c
func! IOBufferSetup()
	let s:workingWindow=winnr()
	let s:workingFileName=@%
	let s:workingFileType=&filetype

	vsplit input.file

	" Save the input window
	let s:inputWindow=winnr()

	vertical resize 60
	split output.file

	" Go back to the input window
	exe s:inputWindow . "wincmd w"
endfunc

func! CloseIOBuffers()
	exe s:workingWindow . "wincmd w"
	execute(":on")
endfunc

func! JumpToCurrent()
	exe s:workingWindow . "wincmd w"
endfunc

" Compile&Run/Run for python,cpp,c
func! CompileAndRun()
	if s:workingFileType ==? "python"
		execute("!cat input.file | python3 ". s:workingFileName ." > output.file")
	elseif s:workingFileType ==? "cpp"
		" g++ test.cpp -o test.cpp.out &&  ./test.cpp.out < input.file > output.file
		execute("! g++ ". s:workingFileName ." -o ". s:workingFileName .".out &&  ./". s:workingFileName .".out< input.file > output.file")

	elseif s:workingFileType ==? "c"
		execute("! gcc ". s:workingFileName ." -o ". s:workingFileName .".out &&  ./". s:workingFileName .".out< input.file > output.file")

	endif
endfunc
