{ Template } = require 'meteor/templating'
Dropbox = require('dropbox')

require './settings.jade'

Template.App_settings.onRendered ->
  NProgress.done()

Template.App_settings.events
  'click #deauthLink': (event) ->
    event.preventDefault()
    Meteor.call 'users.clearDropboxOauth'

  'click #exportLink': (event) ->
    event.preventDefault()
    $('#exportSpinner').fadeIn()
    Meteor.call 'notes.export', {}, (err, res) ->
      $('#exportSpinner').fadeOut()
      $('#exportResult').val(res).fadeIn()

Template.App_settings.helpers
  dropbox_token: ->
    setTimeout ->
      dbx = new Dropbox(clientId: Meteor.settings.public.dropbox_client_id)
      authUrl = dbx.getAuthenticationUrl(Meteor.absoluteUrl() + 'dropboxAuth')
      authLink = document.getElementById('authlink')
      if authLink
        authLink.href = authUrl
    , 100
    if Meteor.user() && Meteor.user().profile
      return Meteor.user().profile.dropbox_token
