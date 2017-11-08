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
    return true
}

Migrations.add {
  version: 2
  up: ->
    users = Meteor.users.find({})
    users.forEach (user) ->
      Meteor.users.update user._id,
        $set:
          referralCount: 0
  down: ->
    return true
}

Migrations.add {
  version: 3
  up: ->
    notes = Notes.find()
    notes.forEach (note) ->
      complete = false
      if note.title && note.title.match Notes.donePattern
        complete = true
      Notes.update note._id,
        $set:
          complete: complete
  down: ->
    return true
}

Migrations.add {
  version: 4
  up: ->
    users = Meteor.users.find({})
    users.forEach (user) ->
      Meteor.users.update user._id,
        $set:
          isPro: true
  down: ->
    return true
}
