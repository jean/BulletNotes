pjson = require('/package.json')
{ Meteor } = require 'meteor/meteor'

Meteor.methods
  'version': (version) ->
    pjson.version