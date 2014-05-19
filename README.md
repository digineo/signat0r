# jQuery signat0r

Draw and capture signatures on canvas surfaces using PointerEvents (mouse,
touch, pen). For a “natural look”, the pen width is adjusted to the pointer
movement speed.

Currently comes with an PointerEvents polyfill: as of writing,
[only IE 10+](http://caniuse.com/#feat=pointer) supports native PointerEvents.


## Use case

For [selbstauskunft.net](https://selbstauskunft.net) (a German, privacy-concerned
web service) we were using a modified drawing javascript from a now long time
retired [Mozilla project](https://github.com/mozilla/markup) to capture signatures
which in turn will included in facsimiles. The code is everything but clean,
and not suitable at all for mobile devices.

Although we have an iOS and Android app, we'd love a pure Web-only approach.
The old Javascript library is one of the last barriers to complete this goal.


## Installation

**Work in progress.**

You will propably need

- `dist/jquery.signat0r.js`,
- `dist/pointerevents.dev.js` (pointer events polyfill from [Polymer/PointerEvents](https://github.com/Polymer/PointerEvents)),
- and [excanvas.js](https://code.google.com/p/explorercanvas/) for IE 8 (and lower) support

Bower support is planned, minified versions will follow.


## Usage

**Work in progress**

See also `src/index.blade` or `demo/index.html`.

### HTML

    <canvas id="signature" touch-action="none">
      Your browser does not support HTML canvas elements.
    </canvas>

    <div>
      <button type="button" id="undo">Undo last stroke</button>
      <button type="button" id="reset">Reset canvas</button>
      <button type="button" id="export">Download</button>
    </div>

### CSS

    #signature {
      /*
        Make the signature area visible. You propably want to open the
        canvas in some kind of fixed-position fullscreen popup/overlay
        on devices with small screens anyway.
      */
      width: 100%;
      height: 400px;
      border: 1px solid #666;

      /*
        Due to limitations of the bundled PointerEvents polyfill **not
        yet really** supported, but hey: if you're living on the
        bleeding edge, why not prepare for the future?
      */
      -webkit-touch-events: none;
      -moz-touch-events: none;
      -ms-touch-events: none;
      -o-touch-events: none;
      touch-events: none;
    }

### Javascript

*(within your DOM ready callback)*

    var options = {} // see below

    var canvas = $('#signature')
    canvas.signat0r(options)

    $('#reset').on('click', function() {
      canvas.signat0r('reset');
    });

    $('#undo').on('click', function() {
      canvas.signat0r('undo');
    });

    $('#export').on('click', function() {
      // holds the (cropped) image as "data;image/png;base64,..." string
      // or is `null` if nothing was drawn
      var pngDataUrl = canvas.signat0r('exportImage');
      if (pngDataUrl) {
        $('<img>').attr('src', pngDataUrl).appendTo($('body'));
      }

      // a list of arrays, contain x/y coordinates as JSON-string
      var samples = canvas.signat0r('exportSamples');
      if (samples) {
        $('body').append("<p>"+samples+"</p>")
      }
    });

A **low level access** to the underlying `Signat0r` instance is possible, but use at your own risk:

    var signator = canvas.data('_signat0r-instance')

    signator.undo()
    signator.reset()
    signator.exportImage()
    signator.resetCanvas()
    signator.render()

    // update options directly
    $.extend(signator.options, {
      style: 'clean'
      debug: true
      // ...
    })

    // update options with a litle more type-safety:
    signator.setOption('minStrokeWidth', '5')
    signator.getOption('minStrokeWidth') // yields `5`, not `"5"`

    // update options through jQuery interface (same as above):
    canvas.signat0r('setOption', 'minStrokeWidth', '5')
    canvas.signat0r('getOption', 'minStrokeWidth') // yields `5`, not `"5"`


The **options** are yet to be detemined, the defaults though are as follows:

    var options = {
      minStrokeWidth: 2,          // Parameter influencing the "variable"
      maxStrokeWidth: 8,          // draw style
      minDistance:    5,          //
      maxDistance:    70,         //

      renderStyle:    'variable', // one of "debug", "clean", "variable". more to come
      cropPadding:    5           //

      debug:          false,      // spam console.log while drawing
    }


As mentioned, different render styles are planned:

- `debug`:    display the pointer events and the distance to the previous point
- `clean`:    a default stroke without any “smudginess” and straight line segments
- `variable`: just like plain, but with a variable stroke width
- `cubic`:    try to use some kind of cubic interpolation to round off the path segments
- `smudgy`:   imagine a pen creating little blots along the way
- `graphite`: adding texture to the stroke, like graphite on paper


## Development

Usually only once do:

- install required NPM packages: `npm install`
- add `./node_modules/.bin` to your `$PATH`

On occasion, run:

- `cake compile` to compile the `demo/index.blade` to `demo/index.html`
- `npm update` for obvious reasons (i.e. `package.json` has changed)

Before hacking, run:

- `cake watch` to auto-comile the CoffeeScripts in `src/`
- `ruby -run -e httpd -- --port=8080 .` to run a local web server (open
  [localhost:8080/demo](http://localhost:8080/demo) in your browser)


## Copyright

Copyright (c) Dominik Menke for [Digineo GmbH](http://www.digineo.de).
See LICENSE for details.
