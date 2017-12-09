{ Meteor } = require 'meteor/meteor'

Meteor.publish 'users.prefs', () ->
  user = Meteor.users.find
    _id: @userId
  ,
    fields:
      menuPin: 1
      muted: 1
      referralCount: 1
      isAdmin: 1
      theme: 1
      language: 1
      isPro: 1
      apiKey: 1
      storeLocation: 1
  user

Meteor.publish 'users.count.total', ->
  new Counter 'users.count.total', Meteor.users.find()

Meteor.publish 'users.count.recent', ->
  new Counter 'users.count.recent', Meteor.users.find()
