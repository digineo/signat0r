Utils =
  # Finds the position of an element (top left corner) in the viewport.
  #
  # Author: Peter-Paul Koch, http://www.quirksmode.org/js/findpos.html
  findPosition: (elem)->
    leftPos = topPos = 0
    if elem.offsetParent
      while true
        leftPos += elem.offsetLeft
        topPos += elem.offsetTop
        break unless elem = elem.offsetParent
    return [leftPos, topPos]

  # Ensures that the given val is in the range [min..max].
  rangeCap: (val, min, max)->
    return min if val < min
    return max if val > max
    val
