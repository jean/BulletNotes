import { Meteor } from 'meteor/meteor'
import { _ } from 'meteor/underscore'
import { ValidatedMethod } from 'meteor/mdg:validated-method'
import SimpleSchema from 'simpl-schema'
import { DDPRateLimiter } from 'meteor/ddp-rate-limiter'

import { Notes } from '/imports/api/notes/notes.coffee'

export updateNoteTags = new ValidatedMethod
  name: 'tags.updateNoteTags'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
  .validator
    clean: yes
    filter: no
  run: ({ noteId }) ->
    if !Meteor.user()
      throw new (Meteor.Error)('not-authorized')

    Meteor.defer ->
      note = Notes.findOne noteId

      if note.title
        tags = note.title.match Notes.hashtagPattern
        if tags
          tags.forEach (tag) ->
            console.log "Save a link to tag: "+tag

        tags = note.title.match Notes.namePattern
        if tags
          tags.forEach (tag) ->
            console.log "Save a link to dude: "+tag

# Get note of all method names on Notes
TAGS_METHODS = _.pluck([
  updateNoteTags
], 'name')

if Meteor.isServer
  # Only allow 5 notes operations per connection per second
  DDPRateLimiter.addRule {
    name: (name) ->
      _.contains TAGS_METHODS, name

    # Rate limit per connection ID
    connectionId: ->
      yes

  }, 5, 1000
