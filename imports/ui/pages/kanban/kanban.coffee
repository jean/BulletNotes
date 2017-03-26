{ Template } = require 'meteor/templating'
{ Notes } = require '/imports/api/notes/notes.coffee'
require './kanban.jade'
require '/imports/ui/components/kanbanList/kanbanList.coffee'

Template.Notes_kanban.onRendered ->
  Meteor.subscribe 'notes.view', FlowRouter.getParam 'noteId'
  Meteor.subscribe 'notes.children', FlowRouter.getParam 'noteId'
  NProgress.done()
  $('.kanbanItem').draggable
    zIndex: 999
    revert: true
    revertDuration: 200
  $('.kanbanList').droppable
    drop: (event, ui) ->
      Meteor.call 'notes.makeChild', {
        noteId: ui.draggable[0].dataset.id
        parent: event.target.dataset.id
        rank: 0
      }

Template.Notes_kanban.helpers
  focusedNote: ->
    Notes.findOne FlowRouter.getParam('noteId')
  childNotes: ->
    Notes.find {
      parent: FlowRouter.getParam('noteId')
    }, sort: rank: 1
