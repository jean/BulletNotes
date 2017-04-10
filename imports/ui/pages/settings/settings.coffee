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

  'change .themeInput': (event, instance) ->
    Meteor.call 'users.setTheme', {theme:event.target.dataset.name}, (err, res) ->
      Template.App_body.showSnackbar
        message: "Theme Saved"

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
  userId: ->
    Meteor.userId()
  themeChecked: (theme) ->
    if Meteor.user() && theme == Meteor.user().theme
      'checked'

  themes: ->
    [
      {theme:'Mountain'}
      {theme:'City'}
      {theme:'Abstract'}
      {theme:'Snow'}
      {theme:'Field'}
      {theme:'Beach'}
      {theme:'Space'}
    ]
