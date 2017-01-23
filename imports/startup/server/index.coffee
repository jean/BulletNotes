require './fixtures.coffee'
require './register-api.coffee'


Meteor.startup ->
  SyncedCron.add
    name: 'Nightly dropbox export'
    schedule: (parser) ->
      # parser is a later.parse object
      # 4:20 am MST, 7 hours off. Lazy fix. Sue me.
      parser.text 'at 11:20 am'
      # parser.text 'every 5 minutes'
    job: ->
      users = Meteor.users.find({})
      users.forEach (user) ->
        Meteor.call('notes.dropbox',user._id)
  SyncedCron.start()