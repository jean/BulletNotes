{ Meteor } = require 'meteor/meteor'
{ check } = require 'meteor/check'
{ Match } = require 'meteor/check'
Dropbox = require('dropbox')

Meteor.methods
  'users.setDropboxOauth': (access_token) ->
    check access_token, String
    Meteor.users.update {_id:@userId},
      {$set:{"profile.dropbox_token":access_token}}

  'users.clearDropboxOauth': () ->
    Meteor.users.update {_id:@userId}, {$unset:{"profile.dropbox_token"}}

  'users.setMenuPin': (menuPin) ->
    Meteor.users.update {_id:@userId}, {$set:{menuPin:menuPin}}

  'users.setMuted': (muted) ->
    Meteor.users.update {_id:@userId}, {$set:{muted:muted}}
