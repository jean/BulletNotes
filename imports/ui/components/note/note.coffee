{ Template } = require 'meteor/templating'
{ ReactiveDict } = require 'meteor/reactive-dict'
{ Notes } = require '../../../api/notes/notes.coffee'
require './note.jade'
require './note.styl'

# require '../share/share.coffee'
import { noteRenderHold } from '../../launch-screen.js';
import { displayError } from '../../lib/errors.js';

Template.note.onRendered ->
  note = this
  Tracker.autorun ->
    newNote = Notes.findOne note.data._id
    if newNote
      $(note.firstNode).find('.title').first().html(
        Template.notes.formatText newNote.title
      )
      if newNote.body
        $(note.firstNode).find('.body').first().show().html(
          Template.notes.formatText newNote.body
        )

  if @data.focusNext
    $(note.firstNode).find('.title').first().focus()

Template.note.helpers
  children: () ->
    if @showChildren
      Meteor.subscribe 'notes.children', @_id
      Notes.find { parent: @_id }, sort: {rank: 1}
  editingClass: (editing) ->
    editing and 'editing'
  expandClass: () ->
    if @children > 0
      if @showChildren || Session.get('expand_'+@_id)
        'glyphicon glyphicon-minus'
      else
        'glyphicon glyphicon-plus'
  className: ->
    className = "note"
    if @title
      tags = @title.match(/#\w+/g)
      if tags
        tags.forEach (tag) ->
          className = className + ' tag-' + tag.substr(1).toLowerCase()
    if @favorite
      className = className + ' favorite'
    if !@showChildren && @children > 0
      className = className + ' hasHiddenChildren'
    if @shared
      className = className + ' shared'
    className

Template.note.events
  'click a.delete': (event) ->
    event.preventDefault()
    $(event.currentTarget).closest('.note').remove()
    Meteor.call 'notes.remove',
      noteId: @_id
      # shareKey: FlowRouter.getParam 'shareKey'

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
          Meteor.call 'notes.updateTitle', {
              noteId: note._id,
              title: topNote
              # shareKey: FlowRouter.getParam('shareKey')
            }, (err, res) ->
              console.log err, res
              Meteor.call 'notes.insert', {
                title: ''
                rank: note.rank + .5
                parent: note.parent
                # shareKey: FlowRouter.getParam('shareKey')
              }, (err, res) ->
                  # Template.notes.calculateRank()
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
            noteId: @_id
            title: title

            # FlowRouter.getParam 'shareKey'
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
          console.log "Remove: ",this
          Meteor.call 'notes.remove',
            noteId: @_id
            # FlowRouter.getParam 'shareKey'
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

  'click .expand': (event) ->
    event.stopImmediatePropagation()
    event.preventDefault()
    if Meteor.userId()
      Meteor.call 'notes.setShowChildren', {
        noteId: @_id
        show: !@showChildren
      }
        # FlowRouter.getParam 'shareKey'
    else
      Session.set 'expand_'+@_id, !Session.get('expand_'+@_id)

Template.note.stripTags = (inputText) ->
  if !inputText
    return
  inputText = inputText.replace(/<\/?span[^>]*>/g, '')
  inputText = inputText.replace(/<\/?a[^>]*>/g, '')
  inputText
