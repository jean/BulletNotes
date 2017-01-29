import { Meteor } from 'meteor/meteor'
import { _ } from 'meteor/underscore'
import { ValidatedMethod } from 'meteor/mdg:validated-method'
import { SimpleSchema } from 'meteor/aldeed:simple-schema'
import { DDPRateLimiter } from 'meteor/ddp-rate-limiter'

import { Notes } from './notes.js'





export insert = new ValidatedMethod
  name: 'notes.insert'
  validate: Notes.simpleSchema().pick([
    'title'
    'rank'
    'level'
    'parent'
  ]).validator
    clean: yes
    filter: no
  run: ({ title, rank, level, parent }) ->
    note = Notes.findOne parent

    # if note.isPrivate() and note.userId isnt @userId
    #   throw new Meteor.Error 'notes.insert.accessDenied', 'Cannot add notes to a private note that is not yours'

    note =
      owner: @userId
      title: title
      parent: parent
      rank: rank
      level: level
      createdAt: new Date()

    Notes.insert note




export updateTitle = new ValidatedMethod
  name: 'notes.updateTitle'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
    newTitle: Notes.simpleSchema().schema('title')
  .validator
    clean: yes
    filter: no
  run: ({ noteId, newTitle }) ->
    # This is complex auth stuff - perhaps denormalizing a userId onto notes
    # would be correct here?
    note = Notes.findOne noteId

    # unless note.editableBy(@userId)
    #   throw new Meteor.Error 'notes.updateTitle.accessDenied', 'Cannot edit notes in a private note that is not yours'

    Notes.update noteId,
      $set:
        title: if _.isUndefined(newTitle) then null else newTitle


export remove = new ValidatedMethod
  name: 'notes.remove'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
  .validator
    clean: yes
    filter: no
  run: ({ noteId }) ->
    note = Notes.findOne noteId

    unless note.editableBy(@userId)
      throw new Meteor.Error 'notes.remove.accessDenied', 'Cannot remove notes in a private note that is not yours'

    Notes.remove noteId


# Get note of all method names on Notes
NOTES_METHODS = _.pluck([
  insert
  updateTitle
  remove
], 'name')

if Meteor.isServer
  # Only allow 5 notes operations per connection per second
  DDPRateLimiter.addRule {
    name: (name) ->
      _.contains NOTES_METHODS, name

    # Rate limit per connection ID
    connectionId: ->
      yes

  }, 5, 1000