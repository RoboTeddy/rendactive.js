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
      data.changes().take(1).onValue -> ctx.invalidate()
      return template(latestData)
    return Spark.attachEvents(eventMap, html)

  {fragment, dataTemplate}
