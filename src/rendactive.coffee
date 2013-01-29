@rendactive = (template, createDataTemplate) ->
  eventMap = {}
  createStream = (selector) ->
    bus = new Bacon.Bus()
    eventMap[selector] = bus.push
    return bus

  dataTemplate = createDataTemplate(createStream)
  latestData = null
  data = Bacon.combineTemplate(dataTemplate)
  data.onValue (v) -> latestData = v

  fragment = Spark.render ->
    html = Spark.isolate ->
      ctx = Meteor.deps.Context.current
      stop = data.changes().onValue -> ctx.invalidate()
      ctx.onInvalidate stop
      return template(latestData)
    return Spark.attachEvents(eventMap, html)

  {fragment, dataTemplate}
