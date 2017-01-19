{ Template } = require 'meteor/templating'
require './settings.jade'
Dropbox = require('dropbox')

Template.settings.onRendered ->
  dbx = new Dropbox(clientId: Meteor.settings.public.dropbox_client_id)
  authUrl = dbx.getAuthenticationUrl('http://localhost:3000/dropboxAuth')
  document.getElementById('authlink').href = authUrl


Template.settings.helpers
  'dropbox_token': ->
    if Meteor.user()
      return Meteor.user().profile.dropbox_token
