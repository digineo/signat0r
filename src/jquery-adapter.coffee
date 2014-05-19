$.fn.signat0r = (options={}, args...)->
  if String(options) == options
    instance = @data '_signat0r-instance'
    return instance[options]?.apply(instance, args)

  else
    instance = new Signat0r(@, options)
    @data '_signat0r-instance', instance
    return @
