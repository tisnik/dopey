" ============================================================================
" Maintainer:  Pavel Tisnovsky <ptisnovs@redhat.com>
" Last Change: 03 May 2017
" ============================================================================

" Exit immediately if the plugin was already loaded, the editor is running in
" vi-compatible mode, or if the editor is too old:
if exists("g:loaded_dopey") || &cp || version < 700
  finish
end
let g:loaded_dopey = 1

" Enable debug messages:
let s:debug = 0

" The s:script_path variable must be initialized OUTSIDE any function. For
" further information Please see :help fnamemodify :help filename-modifers
let s:script_path = fnamemodify(resolve(expand("<sfile>")), ":h")
if s:debug == 1 | echo s:script_path | end

" Read all three data files and return their content as map of list of
" strings.
function! s:ReadDataFiles(sourcesFileName, classesFileName, glossaryFileName)
    let path1 = s:script_path . "/" . a:sourcesFileName
    let path2 = s:script_path . "/" . a:classesFileName
    let path3 = s:script_path . "/" . a:glossaryFileName
    let sources = readfile(path1)
    let classes = readfile(path2)
    let glossary = readfile(path3)
    return {"sources"  : sources,
           \"classes"  : classes,
           \"glossary" : glossary}
endfunction

" Parse word + description from the line read from input file. Return word
" metadata as a map.
function! s:ParseWord(sources, classes, inputLine)
    "                           magic  ID    TERM         DESCRIPTION  CLASS USE   INCORRECT    CORRECT      SEE ALSO     INTERNAL + VERIFIED + COPYRIGHTED + SOURCE
    let l1 = matchlist(a:inputLine, '\v(\d+),''([^'']+)'',''([^'']*)'',(\d+),(\d+),''([^'']*)'',''([^'']*)'',''([^'']*)'',(\d+,\d+,\d+,\d+)')

    " check if line can be parsed.
    if empty(l1)
        echohl ErrorMsg | echo a:inputLine | echohl Normal
        return {}
    endif

    " we use more than 9 groups in one regexp
    " this means that remaining groups has to be handled separately
    let second_part=l1[9]
    let l2 = matchlist(second_part, '\v(\d+),(\d+),(\d+),(\d+)')

    " check if second part of line can be parsed
    if empty(l2)
        echohl ErrorMsg | echo a:inputLine | echohl Normal
        return {}
    endif

    " class field contains just a foreign key to the CLASSES table
    " source field contains just a foreign key to the SOURCES table
    return {"term" :        l1[2],
           \"description" : l1[3],
           \"class"       : a:classes[l1[4]-1],
           \"use"         : l1[5],
           \"incorrect"   : l1[6],
           \"correct"     : l1[7],
           \"see"         : l1[8],
           \"internal"    : l2[0],
           \"verified"    : l2[1],
           \"copyrighted" : l2[2],
           \"source"      : a:sources[l2[3]-1]}
endfunction

" Parse the whole glossary (all lines).
function! s:ParseGlossary(sources, classes, glossaryTextFile)
    let terms = map(a:glossaryTextFile, 's:ParseWord(a:sources, a:classes, v:val)')
    call filter(terms, '!empty(v:val)')
    return terms
endfunction

" Split the given string (content of text line) into words and return number
" of words.
function! s:GetNumWordsInTerm(term)
    let words = split(a:term, " ")
    let numWords = len(words)
    return numWords
endfunction

" Return maximum number of words found in (any) term in the glossary.
function! s:GetMaxWordsInTerms(glossary)
    let maxWords = 0
    for g in a:glossary
        let numWords = s:GetNumWordsInTerm(g.term)
        if numWords > maxWords
            let maxWords = numWords
        endif
    endfor
    return maxWords
endfunction

" Setup function to be called automatically: read data files, parse glossary,
" and compute max number of words found in the glossary.
function! s:Setup()
    let s:dataFiles = s:ReadDataFiles("sources.txt", "classes.txt", "glossary.txt")
    let s:glossary = s:ParseGlossary(s:dataFiles.sources, s:dataFiles.classes, s:dataFiles.glossary)
    let s:maxWords = s:GetMaxWordsInTerms(s:glossary)
    if s:debug == 1
        echo "Number of terms read: " . len(s:glossary)
        echo "Max words in terms:   " . s:maxWords
    end

    "echo len(sources)
    "echo len(classes)
    "echo len(input)
endfunction

function! s:Take(list, cnt)
    let result = []
    for i in range(0, a:cnt-1)
        if i < len(a:list)
            call add(result, get(a:list, i))
        endif
    endfor
    return result
endfunction

function! s:SaveCursorPosition()
    execute("normal!ma")
endfunction

function! s:RestoreCursorPosition()
    execute("normal!`a")
endfunction

function! s:ReadWordsTillEoln()
    call s:SaveCursorPosition()
    let oldRegValue = @"
    execute("normal!vaw$y")
    let result = @"
    let @" = oldRegValue
    call s:RestoreCursorPosition()
    return result
endfunction

function! s:ReadWords(wordsToReturn)
    let wordsTillEoln = s:ReadWordsTillEoln()
    let words = split(wordsTillEoln, " ")
    if len(words) < a:wordsToReturn
        return ""
    endif
    let result = s:Take(words, a:wordsToReturn)
    return join(result, " ")
endfunction

function! s:YesNoCaution(title, value)
    if a:value == 1
        echohl Comment | echon a:title | echohl Question | echon "yes" | echohl None
    elseif a:value == 0
        echohl Comment | echon a:title | echohl ErrorMsg | echon "no" | echohl None
    else
        echohl Comment | echon a:title | echohl WarningMsg | echon "with caution" | echohl None
    endif
endfunction

function! s:ShowTerm(term)
    echohl Comment | echo "Term: " | echohl Question | echon a:term.term | echohl None
    echohl Comment | echo "Description: " | echohl Question | echon a:term.description | echohl None
    echohl Comment | echo "Class: " | echohl Question | echon a:term.class | echohl None
    call s:YesNoCaution("  Use: ", a:term.use)
    call s:YesNoCaution("  Internal: ", a:term.internal)
    call s:YesNoCaution("  Verified: ", a:term.verified)
    call s:YesNoCaution("  Copyrighted: ", a:term.copyrighted)
    echohl Comment | echo "Correct: " | echohl Question | echon a:term.correct | echohl None
    echohl Comment | echo "Incorrect: " | echohl Question | echon a:term.incorrect | echohl None
    echohl Comment | echo "See: " | echohl Question | echon a:term.see | echohl None
    echohl Comment | echo "Source: " | echohl Question | echon a:term.source | echohl None
    echo "\n"
endfunction

function! s:FindTermInGlossary(word)
    let found = 0
    for term in s:glossary
        " use noignorecase comparison
        if term.term ==? a:word
            call s:ShowTerm(term)
            let found = 1
        end
    endfor
    return found
endfunction

" This is the only function residing in the global namespace.
function! SearchGlossary()
    let found = 0
    for i in range(1, s:maxWords)
        let words = s:ReadWords(i)
        if words != ""
            if s:FindTermInGlossary(words)
                let found = 1
                break
            endif
        endif
    endfor
    if !found
        echo "Term not found in the glossary"
    endif
endfunction

" Read and parse glossary and map the SearchGlossary function to given
" keystroke
call s:Setup()
map <F12> :call SearchGlossary()<cr>

"fds abend fd two words fds fd a
"file name fdsafsa

"file name fdsafsa abort
"file name
"abend about

