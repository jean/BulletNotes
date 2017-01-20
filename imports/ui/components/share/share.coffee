{ Template } = require 'meteor/templating'
{ Notes } = require '../../../api/notes/notes.coffee'
require './share.jade'

Template.share.events
  'submit form': (event) ->
    event.preventDefault()
    Meteor.call 'notes.share', this._id
  'click .stopSharing': (event) ->
    event.preventDefault()
    Meteor.call 'notes.stopSharing', this._id

Template.share.helpers
  shareUrl: () ->
    Meteor.absoluteUrl 'note/'+@_id+'/'+@shareKey