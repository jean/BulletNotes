Dropbox = require('dropbox')
import { Meteor } from 'meteor/meteor'
import { _ } from 'meteor/underscore'
import { ValidatedMethod } from 'meteor/mdg:validated-method'
import SimpleSchema from 'simpl-schema'
import { DDPRateLimiter } from 'meteor/ddp-rate-limiter'

Meteor.methods
  'users.clearDropboxOauth': () ->
    Meteor.users.update {_id:@userId}, {$unset:{"profile.dropbox_token"}}

export setDropboxOauth = new ValidatedMethod
  name: 'users.setDropboxOauth'
  validate: new SimpleSchema
    access_token:
      type: String
  .validator
    clean: yes
    filter: no
  run: ({ access_token }) ->
    Meteor.users.update {_id:@userId},
      {$set:{"profile.dropbox_token":access_token}}

export setMenuPin = new ValidatedMethod
  name: 'users.setMenuPin'
  validate: new SimpleSchema
    menuPin:
      type: Boolean
  .validator
    clean: yes
    filter: no
  run: ({ menuPin }) ->
    Meteor.users.update {_id:@userId}, {$set:{menuPin:menuPin}}

export setMuted = new ValidatedMethod
  name: 'users.setMuted'
  validate: new SimpleSchema
    muted:
      type: Boolean
  .validator
    clean: yes
    filter: no
  run: ({ muted }) ->
    Meteor.users.update {_id:@userId}, {$set:{muted:muted}}

export setTheme = new ValidatedMethod
  name: 'users.setTheme'
  validate: new SimpleSchema
    theme:
      type: String
  .validator
    clean: yes
    filter: no
  run: ({ theme }) ->
    Meteor.users.update {_id:@userId}, {$set:{theme:theme}}

USER_METHODS = _.pluck([
  setDropboxOauth
  setMenuPin
  setMuted
  setTheme
], 'name')

if Meteor.isServer
  # Only allow 5 notes operations per connection per second
  DDPRateLimiter.addRule {
    name: (name) ->
      _.contains USER_METHODS, name

    # Rate limit per connection ID
    connectionId: ->
      yes

  }, 5, 1000
