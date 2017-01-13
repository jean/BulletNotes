require './body.jade'
require '../../components/importer/importer.js'
require '../../components/exporter/exporter.js'

Template.App_body.helpers searchTerm: ->
  Session.get 'searchTerm'
Template.App_body.events
  'keydown .searchForm': (event) ->
    if event.keyCode == 13
      event.preventDefault()
      window.location.pathname = '/search/' + event.target.value
    return
  'click .searchForm': (event) ->
    #$(event.target).select();
    return
  'click .searchForm .btn': (event) ->
    window.location.pathname = '/search/' + $('.searchForm input').val()
    return