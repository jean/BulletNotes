{ Template } = require 'meteor/templating'
import {
  share,
  stopSharing
} from '/imports/api/notes/methods.coffee'
require './share.jade'

Template.share.onRendered ->
  checkeventcount = 1
  prevTarget = undefined

Template.share.events
  'click .view': (event) ->
    event.preventDefault()
    share.call
      noteId: this._id
  'click .edit': (event) ->
    event.preventDefault()
    share.call
      noteId: this._id
      editable: true
  'click .stopSharing': (event) ->
    event.preventDefault()
    stopSharing.call
      noteId: this._id
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