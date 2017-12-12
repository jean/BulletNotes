import { Template } from 'meteor/templating'
import { FlowRouter } from 'meteor/kadira:flow-router'

import { Notes } from '/imports/api/notes/notes.coffee'

import { noteRenderHold } from '/imports/ui/launch-screen.js'
import './notes-show-page.jade'

# Components used inside the template
import '/imports/ui/pages/404/app-not-found.coffee'
import '/imports/ui/components/bulletNotes/bulletNotes.coffee'
import '/imports/ui/components/kanban/kanban.coffee'
import '/imports/ui/components/calendar/calendar.coffee'
import '/imports/ui/components/map/map.coffee'

Template.Notes_show_page.onCreated ->
  if !Meteor.user() && !Session.get 'introLoaded'
      FlowRouter.go '/intro'

  @getNoteId = ->
    FlowRouter.getParam 'noteId'

Template.Notes_show_page.onRendered ->
  analytics.page('Note View')
  Session.set 'searchTerm', FlowRouter.getParam 'searchTerm'
  @autorun =>
    if Meteor.user()
      Meteor.call 'notes.setChildrenLastShown', {
        noteId: FlowRouter.getParam 'noteId'
      }
    if @subscriptionsReady()
      noteRenderHold.release()

Template.Notes_show_page.events
  'focus .body': (event, instance) ->
    Session.set 'focused', true
    Template.bulletNoteItem.addAutoComplete event.currentTarget

  'blur .body': (event, instance) ->
    event.stopPropagation()
    that = this
    Session.set 'focused', false
    # console.log event.target
    body = Template.bulletNoteItem.stripTags event.target.innerHTML
    if body != Template.bulletNoteItem.stripTags(@body)
      note = Notes.findOne FlowRouter.getParam 'noteId',
        fields:
          _id: yes
      Meteor.call 'notes.updateBody', {
        noteId: note._id
        body: body
        shareKey: FlowRouter.getParam 'shareKey'
      }, (err, res) ->
        that.body = body
        $(event.target).html Template.bulletNotes.formatText body
    if !body
      $(event.target).fadeOut()

Template.Notes_show_page.helpers
  showNotes: ->
    if Session.get('viewMode') != "kanban" && Session.get('viewMode') != "calendar" && Session.get('viewMode') != "map"
      true

  showKanban: ->
    if Session.get('viewMode') == "kanban"
      true

  showCalendar: ->
    if Session.get('viewMode') == "calendar"
      true

  showMap: ->
    if Session.get('viewMode') == "map"
      true

  focusedNoteId: ->
    FlowRouter.getParam 'noteId'

  focusedNote: ->
    Notes.findOne FlowRouter.getParam 'noteId',
      fields:
        _id: yes
        body: yes
        title: yes
        favorite: yes

  focusedNoteFiles: () ->
    Meteor.subscribe 'files.note', FlowRouter.getParam 'noteId'
    Files.find { noteId: FlowRouter.getParam 'noteId' }

  favorited: ->
    note = Notes.findOne FlowRouter.getParam 'noteId',
      fields:
        _id: yes
        favorite: yes
    if note.favorite
      'favorited'

  progress: ->
    setTimeout ->
      $('[data-toggle="tooltip"]').tooltip()
    , 100
    note = Notes.findOne FlowRouter.getParam 'noteId',
      fields:
        _id: yes
    if note
      note.progress

  progressClass: ->
    note = Notes.findOne FlowRouter.getParam 'noteId',
      fields:
        _id: yes
    Template.bulletNotes.getProgressClass note

  searchTerm: ->
    FlowRouter.getParam 'searchTerm'

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
