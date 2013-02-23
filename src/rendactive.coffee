createHandle = ->
  eventMap = {}
  eventBusMap = {}

  handle =
    creates: new Bacon.Bus()
    renders: new Bacon.Bus()
    destroys: new Bacon.Bus()
    events: (eventSelector) ->
      return eventBusMap[eventSelector] if eventSelector of eventBusMap
      bus = eventBusMap[eventSelector] = new Bacon.Bus()
      eventMap[eventSelector] = bus.push
      return bus
    data: (eventSelector, name) ->
      @events(eventSelector).map((e) -> $(e.target).data(name))
    ids: (eventSelector) -> @data(eventSelector, 'id')
    clicks: (selector) -> @events("click #{selector}")
    changes: (selector) -> @events("change #{selector}")
    enters: (selector) ->
      @events("keydown #{selector}").filter((e) -> e.keyCode == 13)
    blurs: (selector) -> @events("blur #{selector}")
    checkboxBooleans: (selector) ->
      @events("change #{selector}").map((e) -> $(e.target).is(":checked"))
    inputValue: (selector) ->
      @events("keyup #{selector}").map((e) -> $(e.target).val()).toProperty('')
    valueAfterRender: (observable, f) ->
      observable.flatMap((v) => @renders.take(1).map(v)).onValue (v) -> f(v)

  return {handle, eventMap}

@rendactive = (template, createDataTemplate) ->
  {handle, eventMap} = createHandle()
  dataTemplate = createDataTemplate(handle)
  data = Bacon.combineTemplate(dataTemplate)
  latestData = null
  unsubscribe = data.onValue (v) -> latestData = v

  throw "Need initial values in all properties" unless latestData

  mark = null
  fragment = Spark.render ->
    landmarkOptions =
      created: ->
        mark = this
        handle.creates.push this
      rendered: -> handle.renders.push this
      destroyed: ->
        unsubscribe()
        handles.destroys.push this

    Spark.createLandmark landmarkOptions, ->
      html = Spark.isolate ->
        ctx = Meteor.deps.Context.current
        ctx.onInvalidate data.changes().onValue -> ctx.invalidate()
        template(latestData)
      Spark.attachEvents(eventMap, html)

  destroy = -> mark and Spark.finalize(mark.firstNode(), mark.lastNode())
  {fragment, dataTemplate, destroy}
