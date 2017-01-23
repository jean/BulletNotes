require './body.jade'
require '../../components/importer/importer.coffee'
require '../../components/exporter/exporter.coffee'
require '../../components/settings/settings.coffee'
require '../../components/favorites/favorites.coffee'

Template.App_body.onCreated ->
  Meteor.call 'version', (err, version) ->
    $('#version').html version

Template.App_body.onRendered ->
  if !Meteor.userId()
    $.gritter.add
      title: 'Beta Warning'
      text: 'This site is still under construction! While it should work pretty well, and you can and should export regularly, be aware data loss may occur. <a href="https://github.com/NickBusey/BulletNotes/issues" target="_blank">Report Issues on GitHub</a>'
      sticky: true
  $('#undo-redo button').addClass('btn')
  $('#undo-redo br').remove()

Template.App_body.helpers
  searchTerm: ->
    Session.get 'searchTerm'
  year: ->
    moment().format("YYYY")

Template.App_body.events
  'keydown .searchForm': (event) ->
    if event.keyCode == 13
      event.preventDefault()
      window.location.pathname = '/search/' + event.target.value
  'click .searchForm': (event) ->
    #$(event.target).select();
  'click .searchForm .btn': (event) ->
    window.location.pathname = '/search/' + $('.searchForm input').val()
