import { Meteor } from 'meteor/meteor'
import { _ } from 'meteor/underscore'
import { ValidatedMethod } from 'meteor/mdg:validated-method'
import SimpleSchema from 'simpl-schema'
import { DDPRateLimiter } from 'meteor/ddp-rate-limiter'

import { Notes } from '../notes/notes.coffee'
import { Files } from './files.coffee'

export upload = new ValidatedMethod
  name: 'files.upload'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
    data: Files.simpleSchema().schema('data')
  .validator
    clean: yes
  run: ({noteId, data}) ->
    if !@userId
      throw new (Meteor.Error)('not-authorized')
    Files.insert {
      noteId: noteId
      data: data
      owner: @userId
      uploadedAt: new Date
    }

# Get note of all method names on Notes
NOTES_METHODS = _.pluck([
  upload
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
