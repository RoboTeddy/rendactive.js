@rendactive = (template, createDataTemplate) ->
  eventMap = {}
  createStream = (selector) ->
    bus = new Bacon.Bus()
    eventMap[selector] = bus.push
    return bus

  dataTemplate = createDataTemplate(createStream)
  latestData = null
  data = Bacon.combineTemplate(dataTemplate)
  unsubscribe = data.onValue (v) -> latestData = v

  mark = null
  fragment = Spark.render ->
    Spark.createLandmark {destroyed: unsubscribe, created: -> mark = this}, ->
      html = Spark.isolate ->
        ctx = Meteor.deps.Context.current
        ctx.onInvalidate data.changes().onValue -> ctx.invalidate()
        template(latestData)
      Spark.attachEvents(eventMap, html)

  destroy = -> mark and Spark.finalize(mark.firstNode(), mark.lastNode())
  {fragment, dataTemplate, destroy}
