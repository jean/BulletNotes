require './fixtures.coffee'
require './register-api.coffee'


Meteor.startup ->
  process.env.MAIL_URL = 'smtp://postmaster@sandboxaf36916795d84ed1a2f628349543c91c.mailgun.org:63fdcf9f2acbf4aba5745b8e744bd137@smtp.mailgun.org:587'

  SyncedCron.add
    name: 'Nightly email export'
    schedule: (parser) ->
      # parser is a later.parse object
      parser.text 'at 4:20 am'
    job: ->
      users = Meteor.users.find({})
      users.forEach (user) ->
        Meteor.call('notes.email',user._id)
  SyncedCron.start()
