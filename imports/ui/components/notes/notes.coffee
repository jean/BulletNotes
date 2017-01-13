{ Notes } = require '/imports/api/notes/notes.js'
{ Meteor } = require 'meteor/meteor'

require './notes.jade'
require '../note/note.coffee'
require '../breadcrumbs/breadcrumbs.coffee'

newNoteText = 'New note...'
Template.notes.onCreated ->
  if Template.currentData().searchTerm
    Meteor.subscribe 'notes.search', Template.currentData().searchTerm
  else
    Meteor.subscribe 'notes.all'
  return
Template.notes.helpers
  focusedNoteTitle: ->
    if Template.currentData().noteId
      Notes.findOne(Template.currentData().noteId).title
    else
      'Home'
  notes: ->
    if Template.currentData().noteId
      note = Notes.findOne({ parent: Template.currentData().noteId }, sort: rank: 1)
      Session.set 'level', note.level
      Notes.find { parent: Template.currentData().noteId }, sort: rank: 1
    else if Template.currentData().searchTerm
      Session.set 'level', 0
      Notes.find {}
    else
      Session.set 'level', 0
      Notes.find { parent: null }, sort: rank: 1
  newNoteText: ->
    newNoteText
  focusedNote: ->
    Notes.findOne Template.currentData().noteId
Template.notes.events
  'focus #new-note': (event) ->
    if event.currentTarget.innerText == newNoteText
      event.currentTarget.innerText = ''
    return
  'keyup #new-note': (event) ->
    switch event.keyCode
      # Enter
      when 13
        Meteor.call 'notes.insert', event.currentTarget.innerText, null, Template.currentData().noteId, (error) ->
          if error
            alert error.error
          else
            $('#new-note').text ''
          return
      # Escape
      when 27
        $('#new-note').text(newNoteText).blur()
      when 38
        $(event.currentTarget).closest('.note').prev().find('div.title').focus()
    return
  'blur #new-note': (event) ->
    if event.currentTarget.innerText == ''
      $('#new-note').text newNoteText
    return
App = {}

App.calculateRank = ->
  levelCount = 0
  maxLevel = 6
  while levelCount < maxLevel
    $('#notes .level-' + levelCount).each (ii, el) ->
      id = Blaze.getData(this)._id
      Meteor.call 'notes.updateRank', id, ii + 1
      return
    levelCount++
  return

Template.notes.rendered = ->
  @$('#notes').sortable
    handle: '.fa-ellipsis-v'
    stop: (el, ui) ->
      note = Blaze.getData($(el.originalEvent.target).closest('.note').get(0))
      parent_note = Blaze.getData($(el.originalEvent.target).closest('.note').prev().get(0))
      Meteor.call 'notes.makeChild', note._id, parent_note._id, (err, res) ->
        App.calculateRank()
        return
      return
  return

