{ Template } = require 'meteor/templating'
{ ReactiveDict } = require 'meteor/reactive-dict'
{ Notes } = require '../../../api/notes/notes.coffee'
require './note.jade'
# require '../share/share.coffee'

import { noteRenderHold } from '../../launch-screen.js';
import { displayError } from '../../lib/errors.js';

Template.note.onCreated ->
  @subscribe 'notes.children', @data._id

Template.note.helpers
  children: (note) ->
    Notes.find { parent: @_id }, sort: {rank: 1}
  checkedClass: (note) ->
    note.checked and 'checked'
  editingClass: (editing) ->
    editing and 'editing'
  style: () ->
    return 'margin-left:'+(@level)+'em;'

Template.note.events
  'change [type=checkbox]': (event) ->
    checked = $(event.target).is(':checked')

  'keydown .title': (event) ->
    note = this
    event.stopImmediatePropagation()
    switch event.keyCode
      # Enter
      when 13
        event.preventDefault()
        if event.shiftKey
          # Edit the body
          console.log event
          $(event.target).siblings('.body').show().focus()
        else
          # Chop the text in half at the cursor
          # put what's on the left in a note on top
          # put what's to the right in a note below
          console.log window.getSelection().anchorOffset
          console.log event
          position = event.target.selectionStart
          text = event.target.innerHTML
          topNote = text.substr(0, position)
          bottomNote = text.substr(position)
          # Create a new note below the current.
          Meteor.call 'notes.updateTitle',
            note._id,
            topNote,
            FlowRouter.getParam('shareKey'),
            (err, res) ->
              console.log err, res
              Meteor.call 'notes.insert',
                '',
                note.rank + .5,
                note.parent,
                FlowRouter.getParam('shareKey'), (err, res) ->
                  Template.notes.calculateRank()
                  setTimeout (->
                    $(event.target).closest('.note-item').next().find('.title').focus()
                  ), 50
      # Tab
      when 9
        event.preventDefault()
        Session.set 'indenting', true
        # First save the title in case it was changed.
        title = Template.note.stripTags(event.target.innerHTML)
        if title != @title
          Meteor.call 'notes.updateTitle',
            @_id,
            title,
            FlowRouter.getParam 'shareKey'
        parent_id = Blaze.getData(
          $(event.currentTarget).closest('.note-item').prev().get(0)
        )._id
        if event.shiftKey
          Meteor.call 'notes.outdent', {
            noteId: @_id
            # FlowRouter.getParam 'shareKey'
          }
        else
          Meteor.call 'notes.makeChild', {
            noteId: @_id
            parent: parent_id
            rank: null
            # FlowRouter.getParam 'shareKey'
          }
      # Backspace / delete
      when 8
        if event.currentTarget.innerText.trim().length == 0
          $(event.currentTarget).closest('.note-item').prev().find('.title').focus()
          Meteor.call 'notes.remove', {
            noteId: @_id
            # FlowRouter.getParam 'shareKey'
          }
        if window.getSelection().toString() == ''
          position = event.target.selectionStart
          if position == 0
            # We're at the start of the note,
            # add this to the note above, and remove it.
            console.log event.target.value
            prev = $(event.currentTarget).closest('.note-item').prev()
            console.log prev
            prevNote = Blaze.getData(prev.get(0))
            console.log prevNote
            note = this
            console.log note
            Meteor.call 'notes.updateTitle',
              prevNote._id,
              prevNote.title + event.target.value,
              FlowRouter.getParam 'shareKey',
              (err, res) ->
                Meteor.call 'notes.remove',
                  note._id,
                  FlowRouter.getParam 'shareKey',
                  (err, res) ->
                    # Moves the caret to the correct position
                    prev.find('div.title').focus()
      # Up
      when 38
        # Command is held
        if event.metaKey
          $(event.currentTarget).closest('.note-item').find('.expand').trigger 'click'
        else
          if $(event.currentTarget).closest('.note-item').prev().length
            $(event.currentTarget).closest('.note-item').prev().find('div.title').focus()
          else
            # There is no previous note in the current sub list, go up a note.
            $(event.currentTarget).closest('.note-item')
              .parentsUntil('.note-item').siblings('.noteContainer')
              .find('div.title').focus()
      # Down
      when 40
        if event.metaKey
          $(event.currentTarget).closest('.note-item').find('.expand').trigger 'click'
        else
          # Go to a child note if available
          note = $(event.currentTarget).closest('.note-item').find('ol .note').first()
          if !note.length
            # If not, get the next note on the same level
            note = $(event.currentTarget).closest('.note-item').next()
          if !note.length
            # Nothing there, keep going up levels.
            count = 0
            searchNote = $(event.currentTarget).parent().closest('.note-item')
            while note.length < 1 && count < 10
              note = searchNote.next()
              if !note.length
                searchNote = searchNote.parent().closest('.note-item')
                count++
          if note.length
            note.find('div.title').first().focus()
          else
            $('#new-note').focus()
      # Escape
      when 27
        $(event.currentTarget).html Session.get 'preEdit'
        $(event.currentTarget).blur()

  'blur .title': (event, instance) ->
    that = this
    event.stopPropagation()
    # If we blurred because we hit tab and are causing an indent
    # don't save the title here, it was already saved with the
    # indent event.
    if Session.get 'indenting'
      Session.set 'indenting', false
      return
    title = Template.note.stripTags(event.target.innerHTML)
    if title != @title
      Meteor.call 'notes.updateTitle', {
        noteId: instance.data._id
        title: title
        # FlowRouter.getParam 'shareKey',
      }, (err, res) ->
        that.title = title
        $(event.target).html Template.notes.formatText title
  'mousedown .js-delete-item, click .js-delete-item': ->
    remove.call { noteId: @note._id }, displayError
    return

Template.note.stripTags = (inputText) ->
  if !inputText
    return
  inputText = inputText.replace(/<\/?span[^>]*>/g, '')
  inputText = inputText.replace(/<\/?a[^>]*>/g, '')
  inputText
