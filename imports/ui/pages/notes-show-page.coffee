import { Template } from 'meteor/templating'
import { FlowRouter } from 'meteor/kadira:flow-router'

import { Notes } from '/imports/api/notes/notes.coffee'

import { noteRenderHold } from '/imports/ui/launch-screen.js'
import './notes-show-page.jade'

# Components used inside the template
import '/imports/ui/pages/app-not-found.coffee'
import '/imports/ui/components/notes/notes.coffee'


Template.Notes_show_page.onCreated ->
  @getNoteId = ->
    FlowRouter.getParam 'noteId'

Template.Notes_show_page.onRendered ->
  Session.set 'searchTerm', FlowRouter.getParam 'searchTerm'
  @autorun =>
    if @subscriptionsReady()
      noteRenderHold.release()
  Meteor.subscribe 'notes.view',
    FlowRouter.getParam 'noteId'
    FlowRouter.getParam 'shareKey'
  Meteor.subscribe 'notes.children',
    FlowRouter.getParam 'noteId'
    FlowRouter.getParam 'shareKey'

Template.Notes_show_page.helpers
  # We use #each on an array of one item so that the "note" template is
  # removed and a new copy is added when changing notes, which is
  # important for animation purposes.
  noteIdArray: ->
    instance = Template.instance()
    noteId = instance.getNoteId()
    if noteId
      if Notes.findOne(noteId) then [ noteId ] else []
    else
      [ 0 ]

  noteArgs: (noteId) ->
    instance = Template.instance()
    # By finding the note with only the `_id` field set,
    # we don't create a dependency on the
    # `note.incompleteCount`, and avoid re-rendering the todos when it changes
    note = Notes.findOne noteId,
      fields:
        _id: yes

    ret =
      todosReady: instance.subscriptionsReady()
      # We pass `note` (which contains the full note, with all fields, as a function
      # because we want to control reactivity. When you check a todo item, the
      # `note.incompleteCount` changes. If we didn't do this the entire note would
      # re-render whenever you checked an item. By isolating the reactiviy on the note
      # to the area that cares about it, we stop it from happening.
      note: ->
        Notes.findOne noteId
