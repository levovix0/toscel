import std/[strutils]

proc cmpFileNames*(a, b: string): int =
  ## can be used to sort files with numbers in it.
  ## order is [a1, a2, a10, b0, b1, b2, b10] (default cmp is [a1, a10, a2, b0, b1, b10, b2])
  var ai = 0
  var bi = 0
  while ai < a.len and bi < b.len:
    if a[ai] notin '0'..'9' or b[bi] notin '0'..'9':
      if (let r = cmp(a[ai], b[bi]); r != 0): return r
      else:
        inc ai
        inc bi
    
    else:
      var ads = ""
      while ai < a.len and a[ai] in '0'..'9':
        ads.add a[ai]
        inc ai
      
      var bds = ""
      while bi < b.len and b[bi] in '0'..'9':
        bds.add b[bi]
        inc bi

      try:
        if (let r = cmp(ads.parseInt, bds.parseInt); r != 0): return r
      except:
        return cmp(a, b)
  
  return cmp(a.len - ai, b.len - bi)

