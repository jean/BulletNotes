{ Notes } = require '/imports/api/notes/notes.js'
{ Meteor } = require 'meteor/meteor'
{ Mongo } = require 'meteor/mongo'
{ ReactiveDict } = require 'meteor/reactive-dict'
{ Tracker } = require 'meteor/tracker'
{ $ } = require 'meteor/jquery'
{ FlowRouter } = require 'meteor/kadira:flow-router'
{ SimpleSchema } = require 'meteor/aldeed:simple-schema'
{ TAPi18n } = require 'meteor/tap:i18n'

require './notes.html'

import '../note/note.coffee'

import {
  updateTitle,
  makePublic,
  makePrivate,
  remove,
  insert,
} from '../../../api/notes/methods.js'

{ displayError } = '../../lib/errors.js'

Template.notes.onCreated ->
  @subscribe 'notes.children', @data
  @state = new ReactiveDict
  @state.setDefault
    editing: false
    editingNote: false
    notesReady: false

Template.notes.helpers
  notes: ->
    Notes.find { parent: Template.currentData() }, sort: rank: 1
  focusedNote: ->
    Notes.findOne Template.currentData()
  notesReady: ->
    # Template.instance().state.get 'notesReady'
    Template.instance().subscriptionsReady()


Template.notes.events
  'click .js-cancel': (event, instance) ->
    instance.state.set 'editing', false
    return
  'keydown input[type=text]': (event) ->
    # ESC
    if event.which == 27
      event.preventDefault()
      $(event.target).blur()
    return
  'blur input[type=text]': (event, instance) ->
    # if we are still editing (we haven't just clicked the cancel button)
    if instance.state.get('editing')
      instance.saveNote()
    return
  'submit .js-edit-form': (event, instance) ->
    event.preventDefault()
    instance.saveNote()
    return
  'mousedown .js-cancel, click .js-cancel': (event, instance) ->
    event.preventDefault()
    instance.state.set 'editing', false
    return
  'change .note-edit': (event, instance) ->
    target = event.target
    if $(target).val() == 'edit'
      instance.editNote()
    else if $(target).val() == 'delete'
      instance.deleteNote()
    else
      instance.toggleNotePrivacy()
    target.selectedIndex = 0
    return
  'click .js-edit-note': (event, instance) ->
    instance.editNote()
    return
  'click .js-toggle-note-privacy': (event, instance) ->
    instance.toggleNotePrivacy()
    return
  'click .js-delete-note': (event, instance) ->
    instance.deleteNote()
    return
  'click .js-note-add': (event, instance) ->
    instance.$('.js-note-new input').focus()
    return
  'submit .js-note-new': (event) ->
    event.preventDefault()
    $input = $(event.target).find('[type=text]')
    if !$input.val()
      return
    insert.call {
      parent: Template.instance().data
      title: $input.val()
    }, displayError
    $input.val ''
    return
