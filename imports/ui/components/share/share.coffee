{ Template } = require 'meteor/templating'
{ Notes } = require '../../../api/notes/notes.coffee'
require './share.jade'

Template.share.events
  'click .view': (event) ->
    event.preventDefault()
    Meteor.call 'notes.share', this._id
  'click .edit': (event) ->
    event.preventDefault()
    Meteor.call 'notes.share', this._id, true
  'click .stopSharing': (event) ->
    event.preventDefault()
    Meteor.call 'notes.stopSharing', this._id
  'click .fa-copy': (event) ->
    copyTextarea = document.querySelector('.shareUrl')
    copyTextarea.select()
    try
      successful = document.execCommand('copy')
      msg = if successful then 'successful' else 'unsuccessful'
      $.gritter.add
        title: 'Link Copied'
        text: 'Share link copied to your clipboard.'
        time: 1000
Template.share.helpers
  shareUrl: () ->
    Meteor.absoluteUrl 'note/'+@_id+'/'+@shareKey