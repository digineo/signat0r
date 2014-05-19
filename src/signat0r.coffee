class Signat0r
  @defaultOptions =
    minStrokeWidth: 2
    maxStrokeWidth: 8
    minDistance:    5
    maxDistance:    70
    renderStyle:    'variable'
    debug:          false
    cropPadding:    5

  constructor: (@canvas, options)->
    @options = $.extend {}, Signat0r.defaultOptions, options

    @reset()
    @initHandler()

  initHandler: ->
    self = @
    @canvas
    .on 'pointerdown', (e)->
      [x,y] = Utils.findPosition self.canvas.get(0)
      self.samplers[e.originalEvent.pointerId] = new Sampler(x,y)
      return

    .on 'pointermove', (e)->
      return unless (sampler = self.samplers[e.originalEvent.pointerId])?
      sampler.capture(e.originalEvent)
      ctx = self.context(strokeStyle: 'red')
      new CleanRenderer(ctx, [sampler]).render()
      return

    .on 'pointerup', (e)->
      self.samples.push self.samplers[e.originalEvent.pointerId]
      self.samplers[e.originalEvent.pointerId] = null

      self.render()
      return

  reset: ->
    @samplers = {}
    @samples  = []

    @resetCanvas()
    return

  resetCanvas: ->
    c = @canvas.get 0
    c.width = @canvas.width()
    c.height = @canvas.height()
    return

  undo: ->
    if @samples.length
      @samples.pop()
      @render()
      return true
    false

  hasStrokes: ->
    @samples.length && @samples[0].list.length

  exportImage: ->
    return unless @hasStrokes()

    tgt = document.createElement('canvas')
    ctx = tgt.getContext('2d')
    cp  = @cropArea @options.cropPadding
    f   = window.devicePixelRatio || (1500/@canvas.width())

    if f <= 1
      tgt.width  = cp.w
      tgt.height = cp.h

      # capture minimal dimension (+ margin)
      raw = @canvas.get(0).getContext('2d').getImageData(cp.x, cp.y, cp.w, cp.h)
      ctx.putImageData(raw, 0, 0)
    else
      tgt.width         = f * cp.w
      tgt.height        = f * cp.h
      ctx.lineCap       = 'round'
      ctx.lineJoin      = 'bevel'
      ctx.strokeStyle   = 'black'
      @rendererFromOptions(ctx, @normalizedSamples(f)).render()

    return tgt.toDataURL('image/png')

  exportSamples: ->
    JSON.stringify @normalizedSamples()

  normalizedSamples: (scale=1)->
    return [] unless @hasStrokes()

    # make points relative to cropped image origin and scale them
    cp = @cropArea @options.cropPadding
    offset = new Point(cp.x, cp.y)

    @samples.map (sample)->
      sample.list.map (point)->
        point.sub(offset).mul(scale)

  render: ->
    @resetCanvas()
    @rendererFromOptions(@context(), @samples).render()

    if @options.debug
      ctx = @context(strokeStyle: 'green')
      new DebugRenderer(ctx, @samples).render()
    return

  rendererFromOptions: (context, samples)->
    unless r = Renderer.renderers[@options.renderStyle]
      r = CleanRenderer

    new (r)(context, samples, @options)

  context: (options={})->
    ctx = @canvas.get(0).getContext('2d')
    ctx.lineCap      = options.lineCap     || 'round'
    ctx.lineJoin     = options.lineJoin    || 'bevel'
    ctx.lineWidth    = options.lineWidth   || 1
    ctx.strokeStyle  = options.strokeStyle || 'black'
    return ctx

  cropArea: (padding=0)->
    # CSS order (top, right, bottom, left)
    [ymin, xmax, ymax, xmin] = [@canvas.height(), 0, 0, @canvas.width()]

    for sample in @samples
      for p in sample.list
        ymin = p.y if p.y < ymin
        xmax = p.x if p.x > xmax
        ymax = p.y if p.y > ymax
        xmin = p.x if p.x < xmin

    return {
      x: Math.floor(xmin - padding)
      y: Math.floor(ymin - padding)
      w: Math.ceil(xmax + 2*padding - xmin)
      h: Math.ceil(ymax + 2*padding - ymin)
    }

  debug: (msg)->
    return unless @options.debug && console?.debug?
    console.debug "[Signat0r]", msg
    return

  setOption: (which, val)->
    if @options[which]?
      @options[which] = if ['minStrokeWidth', 'maxStrokeWidth', 'minDistance', 'maxDistance'].indexOf(which) >= 0
        parseInt(val, 10)
      else
        val
    else if which == 'samples'
      @samples = val.map (list)->
        s = new Sampler()
        s.list = list.map (p)-> new Point p.x, p.y
        s

      @render()
    return

  getOption: (which)->
    if @options[which]?
      return @options[which]
    return
