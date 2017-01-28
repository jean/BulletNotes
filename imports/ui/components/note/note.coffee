{ Template } = require 'meteor/templating'
{ ReactiveDict } = require 'meteor/reactive-dict'
{ Notes } = require '../../../api/notes/notes.js'
require './note.jade'
# require '../share/share.coffee'

import { displayError } from '../../lib/errors.js';

Template.note.onCreated ->
  @subscribe 'notes.children', @data._id
  return
Template.note.helpers
  children: (note) ->
    console.log note, this
    Notes.find { parent: @_id }, sort: {rank: 1}
  checkedClass: (note) ->
    note.checked and 'checked'
  editingClass: (editing) ->
    editing and 'editing'
Template.note.events
  'change [type=checkbox]': (event) ->
    checked = $(event.target).is(':checked')
    setCheckedStatus.call
      noteId: @note._id
      newCheckedStatus: checked
    return
  'focus input[type=text]': ->
    @onEditingChange true
    return
  'blur input[type=text]': ->
    if @editing
      @onEditingChange false
    return
  'keydown input[type=text]': (event) ->
    # ESC or ENTER
    if event.which == 27 or event.which == 13
      event.preventDefault()
      event.target.blur()
    return
  'blue .title': (event) ->
    console.log event
    updateTitle.call {
      noteId: @note._id
      newTitle: event.target.innerHTML
    }, displayError
    return
  'mousedown .js-delete-item, click .js-delete-item': ->
    remove.call { noteId: @note._id }, displayError
    return
