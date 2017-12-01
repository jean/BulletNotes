import { Meteor } from 'meteor/meteor'
import { _ } from 'meteor/underscore'
import { ValidatedMethod } from 'meteor/mdg:validated-method'
import SimpleSchema from 'simpl-schema'
import { DDPRateLimiter } from 'meteor/ddp-rate-limiter'
import { Random } from 'meteor/random';

export referral = new ValidatedMethod
  name: 'users.referral'
  validate: null
  run: ({ referral }) ->
    Meteor.users.update {_id:referral}, {$inc:{referralCount:1}}
    Meteor.users.update {_id:@userId}, {$set:{referredBy:@userId}}

export generateApiKey = new ValidatedMethod
  name: 'users.generateApiKey'
  validate: null
  run: () ->
    Meteor.users.update {_id:@userId}, {$set:{apiKey:Random.hexString( 32 )}}

# Get note of all method names on Notes
USERS_METHODS = _.pluck([
  referral
], 'name')

if Meteor.isServer
  # Only allow 5 notes operations per connection per second
  DDPRateLimiter.addRule {
    name: (name) ->
      _.contains USERS_METHODS, name

    # Rate limit per connection ID
    connectionId: ->
      yes

  }, 5, 1000
