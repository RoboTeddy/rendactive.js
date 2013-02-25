### global: Bacon, Bacon.UI, Handlebars, rendactive, to_hash, uuid ###
createStorage = (id) ->
  load: -> JSON.parse(localStorage.getItem(this._id) or '[]')
  save: (x) -> localStorage.setItem this._id, JSON.stringify(x)


createActions = ->
  to_hash ([name, new Bacon.Bus()] for name in \
    ['creates', 'destroys', 'edits', 'toggles', 'megatoggles', 'clears'])


createModel = (initialTodos, actions) ->
  mutators =
    append: (newTodo) -> (todos) -> todos.concat [newTodo]
    create: (title) ->
      mutators.append {id: uuid(), title: title, completed: false}
    delete: (id) -> (todos) -> _.reject todos, (t) -> t.id == id
    update: ({id, changes}) -> (todos) -> _.map todos, (t) ->
      if t.id == id then _.defaults(changes, t) else t
    clearCompleted: () -> (todos) -> _.reject todos, (t) -> t.completed
    toggleAll: (completed) -> (todos) -> _.map todos, (t) ->
      _.defaults {completed}, t

  {creates, destroys, edits, toggles, megatoggles, clears} = actions
  # thanks to Juha Paananen for the stream-of-functions pattern!
  mutations = creates.map(mutators.create)
    .merge(destroys.map(mutators.delete))
    .merge(toggles.merge(edits).map(mutators.update))
    .merge(megatoggles.map(mutators.toggleAll))
    .merge(clears.map(mutators.clearCompleted))

  allTodos = mutations.scan initialTodos, (todos, f) -> f(todos)
  activeTodos = allTodos.map (todos) -> _.where todos, completed: false
  completedTodos = allTodos.map (todos) -> _.where todos, completed: true
  {allTodos, activeTodos, completedTodos}


createView = (model, actions, hash) ->
  rendactive Handlebars.compile($('#app').html()), (h) ->
    title = h.inputValue('#new-todo').map((val) -> val.trim())
    h.enters('#new-todo').onValue -> $('#new-todo').val('')

    # convert ui events into actions
    {creates, destroys, edits, toggles, megatoggles, clears} = actions
    creates.plug h.enters('#new-todo').map(title).filter(_.identity)
    destroys.plug h.ids('click [data-action=delete]')
    edits.plug h.enters('.edit').merge(h.blurs('.edit')).map (e) ->
      id: $(e.target).data('id')
      changes: {title: $(e.target).val().trim()}
    destroys.plug edits.filter(({changes}) -> !changes.title).map(({id}) -> id)
    toggles.plug h.changes('[data-action=toggle]').map (e) ->
      id: $(e.target).data('id')
      changes: {completed: $(e.target).is(':checked')}
    megatoggles.plug h.checkboxBooleans('#toggle-all')
    clears.plug h.clicks('#clear-completed')

    editingId = h.ids('dblclick label').merge(edits.map(null)).toProperty(null)
    h.valueAfterRender editingId, (id) -> $('#edit-#{id}').focus()

    {allTodos, activeTodos, completedTodos} = model
    selectedTodos = hash.decode
      '#/': allTodos, '#/active': activeTodos, '#/completed': completedTodos

    {allTodos, completedTodos, activeTodos, selectedTodos, editingId}


createApplication = ->
  hash = Bacon.UI.hash '#/'
  storage = createStorage('todos-rendactive')

  actions = createActions() 
  model = createModel(storage.load(), actions)
  view = createView(model, actions, hash)

  model.allTodos.onValue storage.save
  {model, view, actions}


app = createApplication()
$('body').append(app.view.fragment)
