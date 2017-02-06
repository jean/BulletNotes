# This file configures the Accounts package to define the UI of the reset password email.
require './reset-password-email.js'

# Set up some rate limiting and other important security settings.
require './security.js'

require './register-api.coffee'

Meteor.startup ->
  SyncedCron.add
    name: 'Nightly dropbox export'
    schedule: (parser) ->
      # parser is a later.parse object
      # 4:20 am MST, 7 hours off. Lazy fix. Sue me.
      # parser.text 'at 11:20 am'
      parser.text 'every 5 minutes'
    job: ->
      users = Meteor.users.find({})
      users.forEach (user) ->
        Meteor.call('notes.dropbox',{userId:user._id})
        Meteor.call('notes.summary',{userId:user._id})
  SyncedCron.start()