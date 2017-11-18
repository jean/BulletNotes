{ Template } = require 'meteor/templating'
{ Notes } = require '/imports/api/notes/notes.coffee'
require './kanban.jade'
require '/imports/ui/components/kanbanList/kanbanList.coffee'

import {
  makeChild
} from '/imports/api/notes/methods.coffee'

Template.kanban.onRendered ->
  Meteor.subscribe 'notes.view', FlowRouter.getParam 'noteId'
  Meteor.subscribe 'notes.children', FlowRouter.getParam 'noteId'
  NProgress.done()
  $('.kanbanChildNotes').sortable
    connectWith: '.kanbanChildNotes'
    update: (event, ui) ->
      parent = $(event.toElement).closest('ol').closest('li').data('id')
      if !parent
        parent = FlowRouter.getParam 'noteId'
      upperSibling = $(event.toElement).closest('li').prev('li').data('id')
      makeChild.call
        noteId: $(event.toElement).closest('li').data('id')
        shareKey: FlowRouter.getParam('shareKey')
        upperSibling: upperSibling
        parent: parent

Template.kanban.helpers
  focusedNote: ->
    Notes.findOne FlowRouter.getParam('noteId')
  childNotes: ->
    Notes.find {
      parent: FlowRouter.getParam('noteId')
    }, sort: rank: 1

Template.kanban.events
  'click .newKanbanList header': (event, instance) ->
    Template.App_body.playSound 'newNote'
    note = Notes.findOne FlowRouter.getParam('noteId')
    if note
      children = Notes.find { parent: note._id }
      parent = note._id
    else
      children = Notes.find { parent: null }
      parent = null
    if children
      # Overkill, but, meh. It'll get sorted. Literally.
      rank = (children.count() * 40)
    else
      rank = 1
    Meteor.call 'notes.insert', {
      title: ''
      rank: rank
      parent: parent
      shareKey: FlowRouter.getParam('shareKey')
    }
