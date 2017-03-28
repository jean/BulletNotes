import { Template } from 'meteor/templating'
import { FlowRouter } from 'meteor/kadira:flow-router'

import { Notes } from '/imports/api/notes/notes.coffee'

import { noteRenderHold } from '/imports/ui/launch-screen.js'
import './notes-show-page.jade'

# Components used inside the template
import '/imports/ui/pages/app-not-found.coffee'
import '/imports/ui/components/notes/notes.coffee'
import '/imports/ui/components/kanban/kanban.coffee'
import '/imports/ui/components/calendar/calendar.coffee'


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

Template.Notes_show_page.events
  'change .note-edit': (event, instance) ->
    console.log event, instance
    target = event.target
    if $(target).val() == 'edit'
      instance.editNote()
    else if $(target).val() == 'delete'
      instance.deleteNote()
    else if $(target).val() == 'favorite'
      instance.favoriteNote()
    else if $(target).val() == 'calendar'
      FlowRouter.go('/calendar/'+instance.getNoteId())
    else if $(target).val() == 'kanban'
      FlowRouter.go('/kanban/'+instance.getNoteId())
    target.selectedIndex = 0

  'blur .title-wrapper': (event, instance) ->
    event.stopPropagation()
    title = Template.note.stripTags(event.target.innerHTML)
    if title != @title
      Meteor.call 'notes.updateTitle', {
        noteId: instance.data.note()._id
        title: title
        # FlowRouter.getParam 'shareKey',
      }, (err, res) ->
        $(event.target).html Template.notes.formatText title


Template.Notes_show_page.helpers
  showNotes: ->
    FlowRouter.current().route.name == "Notes.show"

  showKanban: ->
    FlowRouter.current().route.name == "Notes.kanban"

  showCalendar: ->
    FlowRouter.current().route.name == "Notes.calendar"

  focusedNoteId: ->
    FlowRouter.getParam 'noteId'

  focusedNote: ->
    Notes.findOne FlowRouter.getParam 'noteId'

  focusedNoteFiles: () ->
    Meteor.subscribe 'files.note', FlowRouter.getParam 'noteId'
    Files.find { noteId: FlowRouter.getParam 'noteId' }

  favorited: ->
    note = Notes.findOne FlowRouter.getParam 'noteId'
    if note.favorite
      'favorited'

  progress: ->
    setTimeout ->
      $('[data-toggle="tooltip"]').tooltip()
    , 100
    note = Notes.findOne FlowRouter.getParam 'noteId'
    if note
      note.progress

  progressClass: ->
    note = Notes.findOne FlowRouter.getParam 'noteId'
    Template.notes.getProgressClass note

  childNoteCount: ->
    if Notes.findOne FlowRouter.getParam 'noteId'
      Notes.find({parent:FlowRouter.getParam 'noteId'}).count()
    else
      Notes.find({parent:null}).count()

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
