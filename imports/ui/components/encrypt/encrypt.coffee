{ Template } = require 'meteor/templating'
# import {
#   encrypt,
#   stopSharing
# } from '/imports/api/notes/methods.coffee'
require './encrypt.jade'

Template.encrypt.onRendered ->
  checkeventcount = 1
  prevTarget = undefined

Template.encrypt.events

  'click .encryptBtn': (event, instance) ->
    event.preventDefault()

    encrypted = CryptoJS.AES.encrypt(@title, $('.encryptPassword').val()).toString()

    Meteor.call 'notes.updateTitle', {
      noteId: @_id
      title: encrypted
      shareKey: FlowRouter.getParam 'shareKey'
    }

    Meteor.call 'notes.setEncrypted', {
      noteId: @_id
      encrypted: true
    }

    Blaze.getView($('#menuItem_'+@_id)[0]).templateInstance().state.set('showEncrypt', false)
    $('.modal-backdrop.in').fadeOut()

  'click .decryptBtn': (event, instance) ->
    event.preventDefault()

    crypt = CryptoJS.AES.decrypt(@title, $('.decryptPassword').val())
    if !crypt || crypt.toString(CryptoJS.enc.Utf8).length < 1
        alert "Not good"
        return

    decrypted = crypt.toString(CryptoJS.enc.Utf8)

    Meteor.call 'notes.updateTitle', {
      noteId: @_id
      title: decrypted
      shareKey: FlowRouter.getParam 'shareKey'
    }

    Meteor.call 'notes.setEncrypted', {
      noteId: @_id
      encrypted: false
    }
    Blaze.getView($('#menuItem_'+@_id)[0]).templateInstance().state.set('showEncrypt', false)
    $('.modal-backdrop.in').fadeOut()
