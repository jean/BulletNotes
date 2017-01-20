require './view-note.jade'

Template.App_viewNote.onCreated ->
  Session.set 'searchTerm', ''

Template.App_viewNote.helpers noteId: ->
  FlowRouter.getParam 'noteId'

Template.App_viewNote.helpers shareKey: ->
  FlowRouter.getParam 'shareKey'
