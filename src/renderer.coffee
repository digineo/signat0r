class Renderer
  constructor: (@context, @samples, options)->
    @options = $.extend {}, options

  render: ->
    for sample in @samples
      if sample.list?
        @renderPath sample.list
      else
        @renderPath sample
    return

  renderPath: (points)->
    throw "must be implemented in sub class"

class DebugRenderer extends Renderer
  renderPath: (points)->
    last = points[0]
    @context.beginPath()
    @context.arc last.x, last.y, 5, 0, 2*Math.PI, false
    @context.stroke()

    for p in points[1..-1]
      @context.beginPath()
      @context.arc p.x, p.y, 5, 0, 2*Math.PI, false
      @context.stroke()
      @context.font = '9px Arial'
      @context.fillText "#{Math.round p.ds(last)}", p.x, p.y-10
      last = p
    return

class CleanRenderer extends Renderer
  renderPath: (points)->
    return if points.length < 2
    last = points[0]
    lastWidth = @lineWidth points[0].ds(points[1])
    maxDeltaW = 1.5

    for curr in points[1..-1]
      w = @lineWidth curr.ds(last)
      if w > lastWidth + maxDeltaW
        w = lastWidth + maxDeltaW
      else if w < lastWidth - maxDeltaW
        w = lastWidth - maxDeltaW

      @renderSegment curr, last, w
      lastWidth = w
      last = curr
    return

  renderSegment: (p, q, width)->
    @context.beginPath()
    @context.lineWidth = width
    @context.moveTo q.x, q.y
    @context.lineTo p.x, p.y
    @context.stroke()
    return

  lineWidth: (x)->
    @options.minStrokeWidth || 2

class VariableRenderer extends CleanRenderer
  constructor: ->
    super
    @options.m = (@options.minStrokeWidth - @options.maxStrokeWidth) /
                 (@options.maxDistance - @options.minDistance)

  lineWidth: (x)->
    return @options.maxStrokeWidth if x < @options.minDistance
    return @options.minStrokeWidth if x > @options.maxDistance

    @options.maxStrokeWidth + @options.m * (x - @options.minDistance)

$.extend Renderer,
  renderers:
    debug:    DebugRenderer
    clean:    CleanRenderer
    variable: VariableRenderer
