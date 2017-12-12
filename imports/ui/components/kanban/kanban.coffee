{ Template } = require 'meteor/templating'
{ Notes } = require '/imports/api/notes/notes.coffee'

require './kanban.jade'
require '/imports/ui/components/kanbanList/kanbanList.coffee'

import {
  makeChild
} from '/imports/api/notes/methods.coffee'

Template.kanban.onRendered ->
  NProgress.done()
  $('.kanbanChildNotes').sortable
    connectWith: '.kanbanChildNotes'
    handle: '.dot'
    update: (event, ui) ->
      console.log event, ui
      parent = $(event.target).closest('.kanbanList').data('id')
      upperSibling = $(ui.item[0]).prev('li').data('id')
      if upperSibling
        makeChild.call
          noteId: $(ui.item[0]).data('id')
          shareKey: FlowRouter.getParam('shareKey')
          upperSibling: upperSibling
          parent: parent
          expandParent: false
      else
        makeChild.call
          noteId: $(ui.item[0]).data('id')
          shareKey: FlowRouter.getParam('shareKey')
          upperSibling: upperSibling
          parent: parent
          rank: 0

Template.kanban.helpers
  focusedNote: ->
    Notes.findOne FlowRouter.getParam('noteId')
  childNotes: ->
    Notes.find {
      parent: FlowRouter.getParam('noteId')
    }, sort: rank: 1

Template.kanban.events
  'click .newKanbanList header': (event, instance) ->
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
    }, (err, res) ->
      if err
         Template.App_body.showSnackbar
           message: err.message
