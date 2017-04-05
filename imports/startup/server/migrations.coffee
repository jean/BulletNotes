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
}
