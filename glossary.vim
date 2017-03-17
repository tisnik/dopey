function! s:ReadDataFiles(sourcesFileName, classesFileName, glossaryFileName)
    let sources = readfile(a:sourcesFileName)
    let classes = readfile(a:classesFileName)
    let glossary = readfile(a:glossaryFileName)
    return {"sources"  : sources,
           \"classes"  : classes,
           \"glossary" : glossary}
endfunction

function! s:ParseWord(sources, classes, inputLine)
    "                           magic  ID    TERM         DESCRIPTION  CLASS USE   INCORRECT    CORRECT      SEE ALSO     INTERNAL + VERIFIED + COPYRIGHTED + SOURCE
    let l1 = matchlist(a:inputLine, '\v(\d+),''([^'']+)'',''([^'']*)'',(\d+),(\d+),''([^'']*)'',''([^'']*)'',''([^'']*)'',(\d+,\d+,\d+,\d+)')

    if empty(l1)
        echohl ErrorMsg | echo a:inputLine | echohl Normal
        return {}
    endif

    " we use more than 9 groups in one regexp
    " this means that remaining groups has to be handled separately
    let second_part=l1[9]
    let l2 = matchlist(second_part, '\v(\d+),(\d+),(\d+),(\d+)')

    if empty(l2)
        echohl ErrorMsg | echo a:inputLine | echohl Normal
        return {}
    endif

    return {"term" :        l1[2],
           \"description" : l1[3],
           \"class"       : a:classes[l1[4]],
           \"use"         : l1[5],
           \"incorrect"   : l1[6],
           \"correct"     : l1[7],
           \"see"         : l1[8],
           \"internal"    : l2[0],
           \"verified"    : l2[1],
           \"copyrighted" : l2[2],
           \"source"      : a:sources[l2[3]]}
endfunction

function! s:ParseGlossary(sources, classes, glossaryTextFile)
    let terms = map(a:glossaryTextFile, 's:ParseWord(a:sources, a:classes, v:val)')
    call filter(terms, '!empty(v:val)')
    return terms
endfunction

function! s:GetMaxWordsInTerms(glossary)
    let maxWords = 0
    for g in a:glossary
        let term = g.term
        let words = split(term, " ")
        let numWords = len(words)
        if numWords > maxWords
            let maxWords = numWords
        endif
    endfor
    return maxWords
endfunction

function! s:Setup()
    let s:dataFiles = s:ReadDataFiles("sources.txt", "classes.txt", "glossary.txt")
    let s:glossary = s:ParseGlossary(s:dataFiles.sources, s:dataFiles.classes, s:dataFiles.glossary)
    let s:maxWords = s:GetMaxWordsInTerms(s:glossary)
    echo "Number of terms read: " . len(s:glossary)
    echo "Max words in terms:   " . s:maxWords

    "echo len(sources)
    "echo len(classes)
    "echo len(input)
endfunction

call s:Setup()

echo s:glossary[20]

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

function! SearchGlossary()
    for i in range(1, s:maxWords)
        let words = s:ReadWords(i)
        if words != ""
            echo words
        endif
    endfor
endfunction

"echohl ErrorMsg
"|
"echohl
"expand(<cword>)
"
"let line=getline('.')
"col('.')
"col('$')
"string[from:to]
"execute("normal!\"xy2aw")
"fds fd two words fds fd a
