{ Meteor } = require 'meteor/meteor'
{ check } = require 'meteor/check'
{ Match } = require 'meteor/check'
{ Notes } = require '../notes.coffee'

Meteor.publish 'notes.calendar', () ->
  Notes.find
    owner: @userId
    due: {$exists: true}
    deleted: {$exists: false}

Meteor.publish 'notes.view', (noteId, shareKey = null) ->
  check noteId, Match.Maybe(String)
  check shareKey, Match.Maybe(String)
  if shareKey
    if Notes.getSharedParent noteId, shareKey
    # We have a valid shared parent key for this noteid and shareKey
    # Go ahead and return the requested note.
      note = Notes.find
        _id: noteId
        deleted: {$exists: false}
  else
    note = Notes.find
      owner: @userId
      _id: noteId
      deleted: {$exists: false}

  Notes.update noteId, $set:
    updatedAt: new Date

  return note

Meteor.publish 'notes.children', (noteId, shareKey = null) ->
  check noteId, Match.Maybe(String)
  check shareKey, Match.Maybe(String)
  if shareKey
    note = Notes.findOne noteId
    # If we don't have a valid shared note, look at the parents,
    # is one of them valid?
    if Notes.getSharedParent noteId, shareKey
      # One of the parents is validly shared, return the original note
      notes = Notes.find
        parent: noteId
        deleted: {$exists: false}
  else
    notes = Notes.find
      owner: @userId
      parent: noteId
      deleted: {$exists: false}

Meteor.publish 'notes.favorites', ->
  Notes.find
    owner: @userId
    favorite: true
    deleted: {$exists: false}

Meteor.publish 'notes.search', (search) ->
  Notes.search search, this.userId
