template = _.template($('#flickr_template').text())

ui = rendactive template, (createStream) ->
  nexts = createStream('click .next-page')
  prevs = createStream('click .prev-page')
  pageFlips = nexts.map(1).merge(prevs.map(-1))
  query = createStream('keyup input')
    .map((e) -> $(e.target).val())
    .skipDuplicates()
    .toProperty('')

  firstPage = 1
  # when the query changes, we begin again at the first page
  page = query.flatMapLatest ->
      pageFlips.scan(firstPage, (x, y) -> Math.max(firstPage, x + y))
    .skipDuplicates()
    .toProperty(firstPage)

  searches = Bacon.combineTemplate({page, query})
    .filter(({page, query}) -> query.length)

  results = searches.throttle(200).log().flatMapLatest ({page, query}) ->
    Bacon.fromPromise $.get 'http://api.flickr.com/services/rest/',
      method: 'flickr.photos.search'
      format: 'json'
      nojsoncallback: 1
      api_key: '07e0436936cf6efba41e7aa162049442'
      tags: query
      page: page
      per_page: 16

  # when there is no query, photos = null
  photos = results.map((x) -> x?.photos?.photo)
    .merge(query.filter((q) -> q is '').map(null))
    .toProperty(null)

  isLoading = searches.map(true)
    .changes()
    .merge(results.map(false))
    .toProperty(false)

  getPhotoUrl = (photo, size = 'q') ->
    host = "farm#{photo.farm}.staticflickr.com"
    "http://#{host}/#{photo.server}/#{photo.id}_#{photo.secret}_#{size}.jpg"

  {photos, page, isLoading, getPhotoUrl}

$('body').append(ui.fragment)
$('input').focus()
