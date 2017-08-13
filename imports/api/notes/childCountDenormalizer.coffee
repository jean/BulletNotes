import { _ } from 'meteor/underscore'
import { check } from 'meteor/check'

import { Notes } from './notes.coffee'

export default childCountDenormalizer =
  _updateNote: (noteId) ->
    # Recalculate the correct incomplete count direct from MongoDB
    childCount = Notes.find
      parent: noteId
      deleted: {$exists: false}
    .count()

    Notes.update noteId, $set: children: childCount

  afterInsertNote: (noteId) ->
    @_updateNote noteId

  afterRemoveNotes: (notes) ->
    notes.forEach (note) =>
      @_updateNote note.noteId
