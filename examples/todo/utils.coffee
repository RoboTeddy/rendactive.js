### global: Handlebars ###
@uuid = ->
  'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) ->
    r = Math.random() * 16 | 0
    v = if c is 'x' then r else (r & 0x3|0x8)
    v.toString(16)
  )

@to_hash = (pairs) ->
  hash = {}
  hash[key] = value for [key, value] in pairs
  hash

Handlebars.registerHelper 'if_eq', (context, options) ->
  return options.fn(this) if (context == options.hash.compare)
  return options.inverse(this)
