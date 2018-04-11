" Directory used for notes
if !exists('g:notes_directory')
  let g:notes_directory = $HOME . '/notes'
end

" `mod` used to create a new window. See `:h mods`.
if !exists('g:notes_default_mod')
  let g:notes_default_mod = 'vert'
end


" Extension used for note files
if !exists('g:notes_extension')
  let g:notes_extension = 'md'
end

" Print useful messages when debuging this plugin
let g:notes_verbose = 1
if !exists('g:notes_verbose')
  let g:notes_verbose = 0
end


function! s:ensure_direcotry()
  if !isdirectory(g:notes_directory)
    call mkdir(g:notes_directory, "p")
  end
endfunction

function! s:close_note(name)
  let l:cmd = printf('bdelete %s', a:name)
  exec l:cmd
endfunction

function! s:to_filename(note)
  return printf("%s/%s.%s", g:notes_directory, a:note, g:notes_extension)
endfunction

function! s:show(filename, opts)
  let l:cmd = printf("%s new %s", a:opts.mod, a:filename)
  exec l:cmd
endfunction

function! s:append(filename, content, opts)
  call writefile(a:content, a:filename, "a")
endfunction

function! s:block(start, lines)
  if a:lines == []
    return []
  else
    let l:file=expand('%:p:~')
    let l:extension=expand('%:e')
    return ["> " . l:file . " @ " . a:start, "```" . l:extension] + a:lines + ["```"]
  end
endfunction

function! notes#new(opts)
  call s:ensure_direcotry()
  let l:args = filter(a:opts, 'v:val != ""')
  let l:opts = extend(l:args, {
                  \ 'mod': g:notes_default_mod,
                  \ 'note': strftime('%Y-%m-%d')
                  \ }, 'keep')
  let l:note = split(l:opts.note, ' ')
  let l:filename = s:to_filename(l:note[0])
  let l:lines = getline(a:opts.line1, a:opts.line2)
  let l:block = s:block(a:opts.line1, l:lines)

  if len(l:note) <= 1
    if l:block == []
      call s:show(l:filename, l:opts)
    else
      call s:append(l:filename, l:block, l:opts)
    end
  else
    let l:content = join(l:note[1:])
    call s:append(l:filename, l:block + [l:content], l:opts)
  end
endfunction

function! notes#list(arg_lead, cmd_line, cursor_pos)
  let list = split(globpath(g:notes_directory, '**/*.' . g:notes_extension), '\n')
  let nice_list = deepcopy(l:list)
  call map(l:nice_list, 'fnamemodify(v:val, ":t:r")')
  return reverse(filter(l:nice_list, 'v:val =~ "^'. a:arg_lead .'"'))
endfunction

command!
  \ -complete=customlist,notes#list
  \ -range=0
  \ -nargs=?
  \ Note
  \ call notes#new({
    \ 'note': <q-args>,
    \ 'mod': <q-mods>,
    \ 'line1': <line1>,
    \ 'line2': <line2>
    \ })
