require './fixtures.coffee'
require './register-api.coffee'


Meteor.startup ->
  SyncedCron.add
    name: 'Nightly dropbox export'
    schedule: (parser) ->
      # parser is a later.parse object
      parser.text 'at 4:20 am'
    job: ->
      users = Meteor.users.find({})
      users.forEach (user) ->
        Meteor.call('notes.dropbox',user._id)
  SyncedCron.start()
