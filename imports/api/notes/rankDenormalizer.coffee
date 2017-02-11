import { _ } from 'meteor/underscore'
import { check } from 'meteor/check'

import { Notes } from './notes.coffee'

export default rankDenormalizer =
  updateSiblings: (noteId) ->
    siblings = Notes.find { parent: noteId }, sort: rank: 1
    count = 0
    siblings.forEach (bro) ->
      count = count + 2
      Notes.update bro._id, {$set:
        rank: count
      }, tx: true
