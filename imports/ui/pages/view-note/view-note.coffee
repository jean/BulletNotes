require './view-note.jade'

Template.App_viewNote.onCreated ->
  Session.set 'searchTerm', ''
  return
Template.App_viewNote.helpers noteId: ->
  FlowRouter.getParam 'noteId'
