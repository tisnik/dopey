function! ReadDataFiles(sourcesFileName, classesFileName, glossaryFileName)
    let sources = readfile(a:sourcesFileName)
    let classes = readfile(a:classesFileName)
    let glossary = readfile(a:glossaryFileName)
    return {"sources"  : sources,
           \"classes"  : classes,
           \"glossary" : glossary}
endfunction

