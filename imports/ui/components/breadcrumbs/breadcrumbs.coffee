{ Template } = require 'meteor/templating';
{ Notes } = require '../../../api/notes/notes.coffee'
require './breadcrumbs.jade'

Template.breadcrumbs.helpers parents: ->
  parents = []
  if @noteId
    note = Notes.findOne(@noteId)
    parent = Notes.findOne(note.parent)
    while parent
      parents.unshift parent
      parent = Notes.findOne(parent.parent)
  parents
