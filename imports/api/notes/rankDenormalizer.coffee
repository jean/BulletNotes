import { _ } from 'meteor/underscore'
import { check } from 'meteor/check'

import { Notes } from './notes.coffee'



export default rankDenormalizer =
  updateChildren: (noteId) ->
    bulk = Notes.rawCollection().initializeUnorderedBulkOp()
    siblings = Notes.find { owner: Meteor.userId(), parent: noteId }, sort: rank: 1
    count = 0
    siblings.forEach (bro) ->
      count = count + 2
      bulk.find({_id:bro._id}).update {$set:
        rank: count
      }

    Meteor.wrapAsync(bulk.execute, bulk)()

