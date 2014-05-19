fs            = require 'fs'
{spawn, exec} = require 'child_process'

PACKAGE = JSON.parse fs.readFileSync 'package.json'

appFiles = [
  'src/utils.coffee'
  'src/renderer.coffee'
  'src/sampler.coffee'
  'src/signat0r.coffee'
  'src/jquery-adapter.coffee'
]

compileCoffee = (watch=false)->
  args = ['-c', '-j', "#{PACKAGE.name}.js", '-o', 'dist/']
  args.push '-w' if watch
  args.push f for f in appFiles
  command 'coffee', args...

compileDemo = ->
  command 'blade', 'src/index.blade', 'demo/index.html'

command = (name, args...)->
  proc = spawn name, args

  log = (buffer)->
    console.log buffer.toString()

  proc.stderr.on 'data', log
  proc.stdout.on 'data', log

  proc.on 'exit', (status)->
    process.exit(1) if status != 0

task 'watch', 'CoffeeScript', ->
  compileDemo()
  compileCoffee true

task 'compile', 'Demo files (Blade to HTML)', ->
  compileDemo()
  compileCoffee()
