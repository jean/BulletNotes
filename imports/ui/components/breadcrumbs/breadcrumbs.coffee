{ Template } = require 'meteor/templating'
{ Notes } = require '../../../api/notes/notes.coffee'
require './breadcrumbs.jade'

Template.breadcrumbs.helpers
  parents: ->
    parents = []
    note = Template.instance().data.note()
    if note
      Meteor.subscribe 'notes.view',
        note.parent,
        FlowRouter.getParam 'shareKey'
      parent = Notes.findOne(note.parent)
      while parent
        parents.unshift parent
        Meteor.subscribe 'notes.view',
          parent.parent,
          FlowRouter.getParam 'shareKey'
        parent = Notes.findOne(parent.parent)
    parents
  focusedTitle: ->
    note = Notes.findOne(@noteId)
    if note
      return note.title
  shareKey: ->
    FlowRouter.getParam 'shareKey'