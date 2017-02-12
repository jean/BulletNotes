# This file configures the Accounts package to define the UI of the reset password email.
require './reset-password-email.js'

# Set up some rate limiting and other important security settings.
require './security.js'

require './register-api.coffee'

Meteor.startup ->
  cronTime = if Meteor.settings.public.cronTime then Meteor.settings.public.cronTime else 'at 11:20 am'
  SyncedCron.add
    name: 'Nightly dropbox export'
    schedule: (parser) ->
      parser.text cronTime
    job: ->
      Meteor.call('notes.dropbox')
      Meteor.call('notes.summary')
  SyncedCron.start()