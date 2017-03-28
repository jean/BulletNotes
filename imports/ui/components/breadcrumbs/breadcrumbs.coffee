{ Template } = require 'meteor/templating'
{ Notes } = require '../../../api/notes/notes.coffee'
require './breadcrumbs.jade'

Template.breadcrumbs.helpers
  parents: ->
    parents = []
    console.log Template.instance()
    console.log Template.instance().data.note()
    note = Template.instance().data.note()
    if note
      parent = Notes.findOne(note.parent)
      while parent
        parents.unshift parent
        parent = Notes.findOne(parent.parent)
    parents
  focusedTitle: ->
    note = Template.instance().data.note()
    if note
      return note.title
  shareKey: ->
    FlowRouter.getParam 'shareKey'

Template.breadcrumbs.events
  "click a": (event, template) ->
    $('#searchForm input').val('')
