require './body.jade'
require '../../components/importer/importer.coffee'
require '../../components/exporter/exporter.coffee'
require '../../components/settings/settings.coffee'

Template.App_body.onCreated ->
  if !Meteor.userId()
    $.gritter.add
      title: 'Beta Warning'
      text: 'This site is still under construction! While it should work pretty well, and you can and should export regularly, be aware data loss may occur. <a href="https://github.com/NickBusey/noted/issues" target="_blank">Report Issues on GitHub</a>'
      sticky: true 

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
