function! ReadDataFiles(sourcesFileName, classesFileName, glossaryFileName)
    let sources = readfile(a:sourcesFileName)
    let classes = readfile(a:classesFileName)
    let glossary = readfile(a:glossaryFileName)
    return {"sources"  : sources,
           \"classes"  : classes,
           \"glossary" : glossary}
endfunction

function! ParseWord(sources, classes, inputLine)
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

