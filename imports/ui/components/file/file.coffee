{ Template } = require 'meteor/templating'
{ ReactiveDict } = require 'meteor/reactive-dict'
{ Notes } = require '/imports/api/notes/notes.coffee'
{ Files } = require '/imports/api/files/files.coffee'

require './file.jade'

Template.file.isImage = true

Template.file.onRendered ->
  thumbnail = this.find('img')
  if thumbnail.naturalWidth == 0
    $(thumbnail).parent().remove()
    $(this.find('.fileDownload')).show()
  $(this.find('.fileModal .delete')).click (event) ->
    if confirm "Are you sure you want to delete this file?"
      Meteor.call 'files.remove',
        id: event.target.dataset.id
      , (err, res) ->
        $('.modal-backdrop').fadeOut().remove()


Template.file.events
  "click .fileImage": (event, template) ->
    $('#__blaze-root').append($(event.currentTarget).siblings('.modal'))

  "click .delete": (event, template) ->
    event.preventDefault()
    event.stopPropagation()
    if confirm "Are you sure you want to delete this file?"
      Meteor.call 'files.remove',
        id: event.target.dataset.id
