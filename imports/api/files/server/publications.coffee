{ Meteor } = require 'meteor/meteor'
{ check } = require 'meteor/check'
{ Match } = require 'meteor/check'
{ Files } = require '../files.coffee'

Meteor.publish 'files.note', (noteId) ->
  check noteId, Match.Maybe(String)
  Files.find
    noteId: noteId
    deleted: {$exists: false}
