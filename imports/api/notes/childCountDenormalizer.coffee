import { _ } from 'meteor/underscore'
import { check } from 'meteor/check'

import { Notes } from './notes.coffee'

export default incompleteCountDenormalizer =
  _updateNote: (noteId) ->
    # Recalculate the correct incomplete count direct from MongoDB
    childCount = Notes.find
      parent: noteId
    .count()

    Notes.update noteId, $set: children: childCount


  afterInsertNote: (note) ->
    @_updateNote note.noteId


  afterUpdateNote: (selector, modifier) ->
    # We only support very limited operations on notes
    check modifier, $set: Object

    # We can only deal with $set modifiers, but that's all we do in this app
    if _.has(modifier.$set, 'checked')
      Notes.find(selector, fields: noteId: 1).forEach (note) =>
        @_updateNote note.noteId


  afterRemoveNotes: (notes) ->
    notes.forEach (note) =>
      @_updateNote note.noteId
