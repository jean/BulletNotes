{ Template } = require 'meteor/templating'
require './settings.jade'
Dropbox = require('dropbox')

Template.settings.events
  'click #deauthlink': (event) ->
    event.preventDefault()
    Meteor.call 'users.clearDropboxOauth'

Template.settings.helpers
  dropbox_token: ->
    if Meteor.user() && Meteor.user().profile
      setTimeout ->
        dbx = new Dropbox(clientId: Meteor.settings.public.dropbox_client_id)
        authUrl = dbx.getAuthenticationUrl(Meteor.absoluteUrl() + 'dropboxAuth')
        document.getElementById('authlink').href = authUrl
      , 100
      return Meteor.user().profile.dropbox_token
