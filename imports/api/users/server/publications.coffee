{ Meteor } = require 'meteor/meteor'

Meteor.publish 'users.prefs', () ->
  user = Meteor.users.find
    _id: @userId
  ,
    fields: { menuPin: 1 }
  user
