if !exists('g:notes_directory')
  let g:notes_directory = $HOME . '/notes'
end

if !exists('g:notes_default_mod')
  let g:notes_default_mod = 'vert'
end

if !exists('g:notes_extension')
  let g:notes_extension = 'md'
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

function! s:block(lines)
  if a:lines == []
    return []
  else
    let l:file=expand('%:p:~')
    let l:extension=expand('%:e')
    return ["> " . l:file . " @ " . a:lines[0], "```" . l:extension] + a:lines + ["```"]
  end
endfunction

function! s:selection(start, end)
  let [l:lnum1, l:col1] = getpos("'<")[1:2]
  let [l:lnum2, l:col2] = getpos("'>")[1:2]
  if l:lnum1 != a:start || l:lnum2 != a:end
    return []
  endif
  if &selection ==# 'exclusive'
    let l:col2 -= 1
  endif
  let l:lines = getline(l:lnum1, l:lnum2)
  if l:lines == []
    return []
  endif
  let l:lines[-1] = l:lines[-1][:l:col2 - 1]
  let l:lines[0] = l:lines[0][l:col1 - 1:]
  let l:delmark = 'delmarks < >'
  exec l:delmark
  return l:lines
endfunction

function! notes#new(opts)
  call s:ensure_direcotry()
  let l:args = filter(a:opts, 'v:val != ""')
  let l:opts = extend(l:args, {
                  \ 'mod': g:notes_default_mod,
                  \ 'note': '',
                  \ 'append': 0,
                  \ }, 'keep')
  let l:note = split(l:opts.note, ' ')
  if len(l:note) > 0 && l:note[0] =~ '^@'
    let l:head = substitute(l:note[0], "^@", "", "")
    let l:note = l:note[1:]
    let l:filename = s:to_filename(l:head)
  else
    let l:filename = s:to_filename(strftime('%Y-%m-%d'))
  end
  let l:lines = s:selection(a:opts.line1, a:opts.line2)
  let l:block = s:block(l:lines)
  let l:content = join(l:note)
  let l:to_append = filter(l:block + [l:content], 'v:val !~ "^\s*$"')

  if len(l:to_append) > 0
    call s:append(l:filename, l:to_append, l:opts)
  end
  if l:opts.append
    if l:to_append == []
      echom "There is nothing to append!"
    else
      echom "I appended " . l:filename . " with your note."
    end
  else
    call s:show(l:filename, l:opts)
  end
endfunction

function! notes#remove(opts)
  call s:ensure_direcotry()
  let l:args = filter(a:opts, 'v:val != ""')
  let l:opts = extend(l:args, {
                  \ 'note': ''
                  \ }, 'keep')
  let l:splitted = split(l:opts.note)
  if len(l:splitted) != 1
    echom "I expect exactly one note."
    return
  end
  let l:note = l:splitted[0]
  if l:note =~ '^@'
    let l:without_at = substitute(l:note, "^@", "", "")
    let l:filename = s:to_filename(l:without_at)
  else
    echom "I didn't find this note " . l:note . ". Notes should start with an @."
    return
  end
  let l:choice = confirm("Delete " . l:filename . " changes?", "&Yes\n&No")
  if l:choice == 1
    call delete(l:filename)
    echom "I deleted " . l:filename . "."
  else
    echom "Nothing deleted."
  end
endfunction

function! notes#list(arg_lead, cmd_line, cursor_pos)
  let list = split(globpath(g:notes_directory, '**/*.' . g:notes_extension), '\n')
  let nice_list = deepcopy(l:list)
  call map(l:nice_list, '"@" . fnamemodify(v:val, ":t:r")')
  return reverse(filter(l:nice_list, 'v:val =~ "^'. a:arg_lead .'"'))
endfunction

command!
  \ -complete=customlist,notes#list
  \ -range
  \ -bang
  \ -nargs=?
  \ Note
  \ call notes#new({
    \ 'note': <q-args>,
    \ 'mod': <q-mods>,
    \ 'line1': <line1>,
    \ 'line2': <line2>,
    \ 'append': <bang>0
    \ })

command!
  \ -complete=customlist,notes#list
  \ -nargs=1
  \ RemoveNote
  \ call notes#remove({
    \ 'note': <q-args>
    \ })

if exists('fzf#vim#files')
  command! -bang -nargs=? Notes
    \ call fzf#vim#files(g:notes_directory, { 'options': '--bind ctrl-a:select-all,ctrl-d:deselect-all' }, <bang>0)
end
if exists('fzf#vim#grep')
  command! -bang -nargs=* SearchNotes
    \ call fzf#vim#grep(
    \   'rg --column --line-number --no-heading --color=always '.shellescape(<q-args>).' '.shellescape(g:notes_directory).'| tr -d "\017"', 1,
    \   { 'options': '--bind ctrl-a:select-all,ctrl-d:deselect-all' },
    \   <bang>0)
end

" TODO SearchNote
