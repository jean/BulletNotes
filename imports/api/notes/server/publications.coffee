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

Meteor.publish 'notes.starred', ->
  Notes.find
    owner: @userId
    starred: true

Meteor.publish 'notes.search', (search) ->
  check search, Match.Maybe(String)
  query = {}
  projection = limit: 100
  if search.indexOf('last-changed:') == 0
    query =
      'updatedAt': $gte: new Date(new Date - (60 * 60 * 1000))
      owner: @userId
  else
    regex = new RegExp(search, 'i')
    query =
      title: regex
      owner: @userId
  Notes.find query, projection
