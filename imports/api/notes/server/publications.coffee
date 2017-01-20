{ Meteor } = require 'meteor/meteor'
{ check } = require 'meteor/check'
{ Match } = require 'meteor/check'
{ Notes } = require '../notes.coffee'

Meteor.publish 'notes.view', (noteId) ->
  check noteId, Match.Maybe(String)
  note = Notes.find
    owner: @userId
    _id: noteId

Meteor.publish 'notes.children', (noteId) ->
  check noteId, Match.Maybe(String)
  notes = Notes.find
    owner: @userId
    parent: noteId

Meteor.publish 'notes.favorites', ->
  Notes.find
    owner: @userId
    favorite: true

Meteor.publish 'notes.search', (search) ->
  Notes.search search