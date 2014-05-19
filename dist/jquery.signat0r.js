// Generated by CoffeeScript 1.7.1
(function() {
  var CleanRenderer, DebugRenderer, Point, Renderer, Sampler, Signat0r, Utils, VariableRenderer,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  Utils = {
    findPosition: function(elem) {
      var leftPos, topPos;
      leftPos = topPos = 0;
      if (elem.offsetParent) {
        while (true) {
          leftPos += elem.offsetLeft;
          topPos += elem.offsetTop;
          if (!(elem = elem.offsetParent)) {
            break;
          }
        }
      }
      return [leftPos, topPos];
    },
    rangeCap: function(val, min, max) {
      if (val < min) {
        return min;
      }
      if (val > max) {
        return max;
      }
      return val;
    }
  };

  Renderer = (function() {
    function Renderer(context, samples, options) {
      this.context = context;
      this.samples = samples;
      this.options = $.extend({}, options);
    }

    Renderer.prototype.render = function() {
      var sample, _i, _len, _ref;
      _ref = this.samples;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        sample = _ref[_i];
        if (sample.list != null) {
          this.renderPath(sample.list);
        } else {
          this.renderPath(sample);
        }
      }
    };

    Renderer.prototype.renderPath = function(points) {
      throw "must be implemented in sub class";
    };

    return Renderer;

  })();

  DebugRenderer = (function(_super) {
    __extends(DebugRenderer, _super);

    function DebugRenderer() {
      return DebugRenderer.__super__.constructor.apply(this, arguments);
    }

    DebugRenderer.prototype.renderPath = function(points) {
      var last, p, _i, _len, _ref;
      last = points[0];
      this.context.beginPath();
      this.context.arc(last.x, last.y, 5, 0, 2 * Math.PI, false);
      this.context.stroke();
      _ref = points.slice(1);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        p = _ref[_i];
        this.context.beginPath();
        this.context.arc(p.x, p.y, 5, 0, 2 * Math.PI, false);
        this.context.stroke();
        this.context.font = '9px Arial';
        this.context.fillText("" + (Math.round(p.ds(last))), p.x, p.y - 10);
        last = p;
      }
    };

    return DebugRenderer;

  })(Renderer);

  CleanRenderer = (function(_super) {
    __extends(CleanRenderer, _super);

    function CleanRenderer() {
      return CleanRenderer.__super__.constructor.apply(this, arguments);
    }

    CleanRenderer.prototype.renderPath = function(points) {
      var curr, last, lastWidth, maxDeltaW, w, _i, _len, _ref;
      if (points.length < 2) {
        return;
      }
      last = points[0];
      lastWidth = this.lineWidth(points[0].ds(points[1]));
      maxDeltaW = 1.5;
      _ref = points.slice(1);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        curr = _ref[_i];
        w = this.lineWidth(curr.ds(last));
        if (w > lastWidth + maxDeltaW) {
          w = lastWidth + maxDeltaW;
        } else if (w < lastWidth - maxDeltaW) {
          w = lastWidth - maxDeltaW;
        }
        this.renderSegment(curr, last, w);
        lastWidth = w;
        last = curr;
      }
    };

    CleanRenderer.prototype.renderSegment = function(p, q, width) {
      this.context.beginPath();
      this.context.lineWidth = width;
      this.context.moveTo(q.x, q.y);
      this.context.lineTo(p.x, p.y);
      this.context.stroke();
    };

    CleanRenderer.prototype.lineWidth = function(x) {
      return this.options.minStrokeWidth || 2;
    };

    return CleanRenderer;

  })(Renderer);

  VariableRenderer = (function(_super) {
    __extends(VariableRenderer, _super);

    function VariableRenderer() {
      VariableRenderer.__super__.constructor.apply(this, arguments);
      this.options.m = (this.options.minStrokeWidth - this.options.maxStrokeWidth) / (this.options.maxDistance - this.options.minDistance);
    }

    VariableRenderer.prototype.lineWidth = function(x) {
      if (x < this.options.minDistance) {
        return this.options.maxStrokeWidth;
      }
      if (x > this.options.maxDistance) {
        return this.options.minStrokeWidth;
      }
      return this.options.maxStrokeWidth + this.options.m * (x - this.options.minDistance);
    };

    return VariableRenderer;

  })(CleanRenderer);

  $.extend(Renderer, {
    renderers: {
      debug: DebugRenderer,
      clean: CleanRenderer,
      variable: VariableRenderer
    }
  });

  Point = (function() {
    Point.ZERO = new Point(0, 0);

    Point.UNIT = new Point(Math.SQRT1_2, Math.SQRT1_2);

    Point.polar = function(length, angle) {
      var x, y;
      x = Math.cos(angle) * length;
      y = Math.sin(angle) * length;
      return new Point(x, y);
    };

    function Point(x, y) {
      this.x = x;
      this.y = y;
    }

    Point.prototype.ds = function(other) {
      var dx, dy;
      dx = Math.pow(this.x - other.x, 2);
      dy = Math.pow(this.y - other.y, 2);
      return Math.sqrt(dx + dy);
    };

    Point.prototype.add = function(other) {
      if (other.x === 0 && other.y === 0) {
        return this;
      }
      return new Point(this.x + other.x, this.y + other.y);
    };

    Point.prototype.mul = function(scalar) {
      if (scalar === 1) {
        return this;
      }
      return new Point(this.x * scalar, this.y * scalar);
    };

    Point.prototype.sub = function(other) {
      return this.add(other.mul(-1));
    };

    Point.prototype.length = function() {
      return this.ds(Point.ZERO);
    };

    Point.prototype.unit = function() {
      var l;
      l = this.length();
      return new Point(this.x / l, this.y / l);
    };

    Point.prototype.normalize = function(length) {
      if (length == null) {
        length = 1;
      }
      return this.unit().mul(length);
    };

    Point.prototype.equals = function(other) {
      return this.x === other.x && (this.y = other.y);
    };

    Point.prototype.toString = function() {
      return "(" + this.x + "," + this.y + ")";
    };

    return Point;

  })();

  Sampler = (function() {
    function Sampler(offsetX, offsetY) {
      this.offsetX = offsetX;
      this.offsetY = offsetY;
      this.list = [];
    }

    Sampler.prototype.capture = function(e) {
      return this.list.push(new Point(Math.round(e.clientX - this.offsetX), Math.round(e.clientY - this.offsetY)));
    };

    return Sampler;

  })();

  Signat0r = (function() {
    Signat0r.defaultOptions = {
      minStrokeWidth: 2,
      maxStrokeWidth: 8,
      minDistance: 5,
      maxDistance: 70,
      renderStyle: 'variable',
      debug: false,
      cropPadding: 5
    };

    function Signat0r(canvas, options) {
      this.canvas = canvas;
      this.options = $.extend({}, Signat0r.defaultOptions, options);
      this.reset();
      this.initHandler();
    }

    Signat0r.prototype.initHandler = function() {
      var self;
      self = this;
      return this.canvas.on('pointerdown', function(e) {
        var x, y, _ref;
        _ref = Utils.findPosition(self.canvas.get(0)), x = _ref[0], y = _ref[1];
        self.samplers[e.originalEvent.pointerId] = new Sampler(x, y);
      }).on('pointermove', function(e) {
        var ctx, sampler;
        if ((sampler = self.samplers[e.originalEvent.pointerId]) == null) {
          return;
        }
        sampler.capture(e.originalEvent);
        ctx = self.context({
          strokeStyle: 'red'
        });
        new CleanRenderer(ctx, [sampler]).render();
      }).on('pointerup', function(e) {
        self.samples.push(self.samplers[e.originalEvent.pointerId]);
        self.samplers[e.originalEvent.pointerId] = null;
        self.render();
      });
    };

    Signat0r.prototype.reset = function() {
      this.samplers = {};
      this.samples = [];
      this.resetCanvas();
    };

    Signat0r.prototype.resetCanvas = function() {
      var c;
      c = this.canvas.get(0);
      c.width = this.canvas.width();
      c.height = this.canvas.height();
    };

    Signat0r.prototype.undo = function() {
      if (this.samples.length) {
        this.samples.pop();
        this.render();
        return true;
      }
      return false;
    };

    Signat0r.prototype.hasStrokes = function() {
      return this.samples.length && this.samples[0].list.length;
    };

    Signat0r.prototype.exportImage = function() {
      var cp, ctx, f, raw, tgt;
      if (!this.hasStrokes()) {
        return;
      }
      tgt = document.createElement('canvas');
      ctx = tgt.getContext('2d');
      cp = this.cropArea(this.options.cropPadding);
      f = window.devicePixelRatio || (1500 / this.canvas.width());
      if (f <= 1) {
        tgt.width = cp.w;
        tgt.height = cp.h;
        raw = this.canvas.get(0).getContext('2d').getImageData(cp.x, cp.y, cp.w, cp.h);
        ctx.putImageData(raw, 0, 0);
      } else {
        tgt.width = f * cp.w;
        tgt.height = f * cp.h;
        ctx.lineCap = 'round';
        ctx.lineJoin = 'bevel';
        ctx.strokeStyle = 'black';
        this.rendererFromOptions(ctx, this.normalizedSamples(f)).render();
      }
      return tgt.toDataURL('image/png');
    };

    Signat0r.prototype.exportSamples = function() {
      return JSON.stringify(this.normalizedSamples());
    };

    Signat0r.prototype.normalizedSamples = function(scale) {
      var cp, offset;
      if (scale == null) {
        scale = 1;
      }
      if (!this.hasStrokes()) {
        return [];
      }
      cp = this.cropArea(this.options.cropPadding);
      offset = new Point(cp.x, cp.y);
      return this.samples.map(function(sample) {
        return sample.list.map(function(point) {
          return point.sub(offset).mul(scale);
        });
      });
    };

    Signat0r.prototype.render = function() {
      var ctx;
      this.resetCanvas();
      this.rendererFromOptions(this.context(), this.samples).render();
      if (this.options.debug) {
        ctx = this.context({
          strokeStyle: 'green'
        });
        new DebugRenderer(ctx, this.samples).render();
      }
    };

    Signat0r.prototype.rendererFromOptions = function(context, samples) {
      var r;
      if (!(r = Renderer.renderers[this.options.renderStyle])) {
        r = CleanRenderer;
      }
      return new r(context, samples, this.options);
    };

    Signat0r.prototype.context = function(options) {
      var ctx;
      if (options == null) {
        options = {};
      }
      ctx = this.canvas.get(0).getContext('2d');
      ctx.lineCap = options.lineCap || 'round';
      ctx.lineJoin = options.lineJoin || 'bevel';
      ctx.lineWidth = options.lineWidth || 1;
      ctx.strokeStyle = options.strokeStyle || 'black';
      return ctx;
    };

    Signat0r.prototype.cropArea = function(padding) {
      var p, sample, xmax, xmin, ymax, ymin, _i, _j, _len, _len1, _ref, _ref1, _ref2;
      if (padding == null) {
        padding = 0;
      }
      _ref = [this.canvas.height(), 0, 0, this.canvas.width()], ymin = _ref[0], xmax = _ref[1], ymax = _ref[2], xmin = _ref[3];
      _ref1 = this.samples;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        sample = _ref1[_i];
        _ref2 = sample.list;
        for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
          p = _ref2[_j];
          if (p.y < ymin) {
            ymin = p.y;
          }
          if (p.x > xmax) {
            xmax = p.x;
          }
          if (p.y > ymax) {
            ymax = p.y;
          }
          if (p.x < xmin) {
            xmin = p.x;
          }
        }
      }
      return {
        x: Math.floor(xmin - padding),
        y: Math.floor(ymin - padding),
        w: Math.ceil(xmax + 2 * padding - xmin),
        h: Math.ceil(ymax + 2 * padding - ymin)
      };
    };

    Signat0r.prototype.debug = function(msg) {
      if (!(this.options.debug && ((typeof console !== "undefined" && console !== null ? console.debug : void 0) != null))) {
        return;
      }
      console.debug("[Signat0r]", msg);
    };

    Signat0r.prototype.setOption = function(which, val) {
      if (this.options[which] != null) {
        this.options[which] = ['minStrokeWidth', 'maxStrokeWidth', 'minDistance', 'maxDistance'].indexOf(which) >= 0 ? parseInt(val, 10) : val;
      } else if (which === 'samples') {
        this.samples = val.map(function(list) {
          var s;
          s = new Sampler();
          s.list = list.map(function(p) {
            return new Point(p.x, p.y);
          });
          return s;
        });
        this.render();
      }
    };

    Signat0r.prototype.getOption = function(which) {
      if (this.options[which] != null) {
        return this.options[which];
      }
    };

    return Signat0r;

  })();

  $.fn.signat0r = function() {
    var args, instance, options, _ref;
    options = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    if (options == null) {
      options = {};
    }
    if (String(options) === options) {
      instance = this.data('_signat0r-instance');
      return (_ref = instance[options]) != null ? _ref.apply(instance, args) : void 0;
    } else {
      instance = new Signat0r(this, options);
      this.data('_signat0r-instance', instance);
      return this;
    }
  };

}).call(this);