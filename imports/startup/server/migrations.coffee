import { Notes } from '/imports/api/notes/notes.coffee'

Migrations.add {
  version: 1
  up: ->
    notes = Notes.find
      children: $gte: 1
    notes.forEach (note) ->
      Notes.update note._id,
        $set:
          childrenLastShown: new Date
  down: ->
    console.log "wtf"
}

Migrations.add {
  version: 2
  up: ->
    console.log "?"
    users = Meteor.users.find({})
    users.forEach (user) ->
      Meteor.users.update user._id,
        $set:
          referralCount: 0
  down: ->
    return true
}
