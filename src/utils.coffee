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

  # adapted from http://www.cartogrammar.com/blog/actionscript-curves-update/
  curveThroughPoints: (ctx, points, z=0.5, angleFactor=0.75, debug=false)->
    p = points.slice 0  # Local copy of points array

    # sometimes, there is just nothing to do
    if p.length < 2
      return
    if p.length == 2
      ctx.beginPath()
      ctx.moveTo p[0].x, p[0].y
      ctx.lineTo p[1].x, p[1].y
      ctx.stroke()
      return

    # normalize z/angleFactor
    z = Utils.rangeCap(z, 0, 1) || 0.5
    angleFactor = Utils.rangeCap angleFactor, 0, 1


    #
    # First calculate all the curve control points
    #

    # An array to store the two control points (of a cubic Bézier curve)
    # for each point
    controlPts = []

    # Loop through all the points to get curve control points for each.
    for i in [1...p.length-1]
      # The previous, current, and next points
      p0 = p[i-1]
      p1 = p[i]
      p2 = p[i+1]

      a = p0.ds p1 # distance from prev to curr
      b = p1.ds p2 #               curr to next
      c = p0.ds p2 #               prev to next

      a = 0.001 if a < 0.001 # cheap way to prevent div/0 errors
      b = 0.001 if b < 0.001 #
      c = 0.001 if c < 0.001 #


      # Angle formed by the two sides of the triangle (described by the
      # three points above) adjacent to the current point
      cos = Utils.rangeCap ((a*a + b*b - c*c) / (2*a*b)), -1, 1
      C = Math.acos(cos)

      # Duplicate set of points. Start by giving previous and next points values RELATIVE to the current point.
      aPt = p0.sub p1
      bPt = new Point p1.x, p1.y
      cPt = p2.sub p1

      # We'll be adding the vectors from the previous and next points to the
      # current point, but we don't want differing magnitudes (i.e. line segment
      # lengths) to affect the direction of the new vector.
      #
      # Therefore we make sure the segments we use, based on the duplicate
      # points created above, are of equal length.
      #
      # The angle of the new vector will thus bisect angle C and the perpendicular
      # to this is nice for the line tangent to the curve.
      #
      # The curve control points will be along that tangent line.

      if a > b
        # Scale the segment to aPt (bPt to aPt) to the size of b (bPt to cPt) if b is shorter.
        aPt = aPt.normalize(b)
      else if b > a
        # Scale the segment to cPt (bPt to cPt) to the size of a (aPt to bPt) if a is shorter.
        cPt = cPt.normalize(a)


      # Offset aPt and cPt by the current point to get them back to their
      # absolute position.
      aPt = aPt.add p1
      cPt = cPt.add p1

      # Get the sum of the two vectors, which is perpendicular to the line
      # along which our curve control points will lie.
      aX = bPt.x - aPt.x  # from previous to current point
      aY = bPt.y - aPt.y

      bX = bPt.x - cPt.x  # from next to current point
      bY = bPt.y - cPt.y

      rX = aX + bX
      rY = aY + bY

      # Correct for three points in a line by finding the angle between
      # just two of them
      if rX == 0 && rY == 0
        rX = bX    # Really not sure why this seems to have to be negative
        rY = bY

      # Switch rX and rY when y or x difference is 0. This seems to prevent
      # the angle from being perpendicular to what it should be.
      if aY == 0 && bY == 0
        rX = 0
        rY = 1
      else if aX == 0 && bX == 0
        rX = 1
        rY = 0

      # angle of the new vector
      theta = Math.atan2(rY, rX)

      # Distance of curve control points from current point:
      # a fraction the length of the shorter adjacent triangle side
      controlDist = Math.min(a, b) * z

      # Scale the distance based on the acuteness of the angle.
      # Prevents big loops around long, sharp-angled triangles.
      controlScaleFactor = C / Math.PI

      # Mess with this for some fine-tuning
      controlDist *= ((1-angleFactor) + angleFactor*controlScaleFactor)
      console.log controlDist

      # The angle from the current point to control points:
      # the new vector angle plus 90 degrees (tangent to the curve).
      controlAngle = theta + Math.PI / 2

      # Control point 2, curving to the next point.
      cp2 = Point.polar(controlDist, controlAngle).add(p1)

      # Control point 1, curving from the previous point
      # (180 degrees away from control point 2).
      cp1 = Point.polar(controlDist, controlAngle+Math.PI).add(p1)

      # Haven't quite worked out how this happens, but some control points
      # will be reversed.
      #
      # In this case cp2 will be farther from the next point than cp1 is.
      #
      # Check for that and switch them if it's true.
      if cp2.ds(p2) > cp1.ds(p2)
        # Add the two control points to the array in reverse order
        controlPts[i] = [cp2, cp1]
      else
        # Otherwise add the two control points to the array in normal order
        controlPts[i] = [cp1, cp2]

      # draw lines showing where the control points are
      if debug
        ctx.beginPath()
        old =
          lineWidth:    ctx.lineWidth
          strokeStyle:  ctx.strokeStyle
        ctx.lineWidth   = 1
        ctx.strokeStyle = '#aaa'

        ctx.moveTo p1.x, p1.y
        ctx.lineTo cp2.x, cp2.y
        ctx.moveTo p1.x, p1.y
        ctx.lineTo cp1.x, cp1.y
        ctx.stroke()

        ctx.lineWidth   = old.lineWidth
        ctx.strokeStyle = old.strokeStyle

    #
    # Now draw the curve
    #

    ctx.beginPath()
    ctx.moveTo p[0].x, p[0].y

    # Draw a regular quadratic Bézier curve from the first to second points,
    # using the first control point of the second point
    ctx.quadraticCurveTo controlPts[1][0].x, controlPts[1][0].y, p[1].x, p[1].y

    # Loop through points to draw cubic Bézier curves through the penultimate point
    for i in [1...p.length-2]
      ctx.bezierCurveTo controlPts[i][1].x, controlPts[i][1].y, controlPts[i+1][0].x, controlPts[i+1][0].y, p[i+1].x, p[i+1].y

    # Curve to the last point using the second control point of the
    # penultimate point.
    ctx.quadraticCurveTo controlPts[i][1].x, controlPts[i][1].y, p[i+1].x, p[i+1].y
    ctx.stroke()
