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
      theme: 'mountain'
  user

Meteor.publish 'users.count', ->
  new Counter 'total', Meteor.users.find
