import { Mongo } from 'meteor/mongo'
import { Factory } from 'meteor/dburles:factory'
import { SimpleSchema } from 'meteor/aldeed:simple-schema'
import faker from 'faker'
import childCountDenormalizer from './childCountDenormalizer.coffee'
sanitizeHtml = require('sanitize-html')

# class NotesCollection extends Mongo.Collection
#   insert: (doc, callback) ->
#     ourDoc = doc
#     ourDoc.createdAt = ourDoc.createdAt or new Date()
#     result = super ourDoc, callback
#     childCountDenormalizer.afterInsertNote ourDoc
#     result


#   update: (selector, modifier) ->
#     result = super selector, modifier
#     childCountDenormalizer.afterUpdateNote selector, modifier
#     result


#   remove: (selector) ->
#     notes = @find(selector).fetch()
#     result = super selector
#     childCountDenormalizer.afterRemoveNotes notes
#     result

export Notes = new Mongo.Collection 'notes'


Notes.isEditable = (id, shareKey) ->
  sharedNote = Notes.getSharedParent id, shareKey
  # If we have a shareKey but can't find a valid sharedNote,
  # aren't the sharedNote's owner,
  # or the sharedNote is not set to sharedEditable, don't allow.
  if shareKey && (
    !sharedNote || (
      sharedNote.owner != @userId && !sharedNote.sharedEditable
    )
  )
    return false
  else
    return true

Notes.getSharedParent = (id, shareKey) ->
  note = Notes.findOne id
  while note && (note.shareKey != shareKey || note.shared == false)
    note = Notes.findOne note.parent
  if (note && note.shareKey == shareKey && note.shared == true)
    return note

Notes.filterTitle = (title) ->
  title = title.replace(/(\r\n|\n|\r)/gm, '')
  sanitizeHtml title,
    allowedTags: [
      'b'
      'i'
      'em'
      'strong'
    ]

Notes.search = (search, userId = null) ->
  check search, Match.Maybe(String)
  query = {}
  projection = limit: 100
  if !userId
    userId =  @userId
  if search.indexOf('last-changed:') == 0
    myRegexp = /last-changed:([0-9]+)([a-z]+)/gim
    match = myRegexp.exec(search)
    query =
      'updatedAt': $gte: moment().subtract(match[1], match[2]).toDate()
      owner: userId
  else if search.indexOf('not-changed:') == 0
    myRegexp = /not-changed:([0-9]+)([a-z]+)/gim
    match = myRegexp.exec(search)
    query =
      'updatedAt': $lte: moment().subtract(match[1], match[2]).toDate()
      owner: userId
  else
    regex = new RegExp(search, 'i')
    query =
      title: regex
      owner: userId
  query.deleted = {$exists: false}
  Notes.find query, projection

# Deny all client-side updates since we will
# be using methods to manage this collection
Notes.deny
  insert: -> yes
  update: -> yes
  remove: -> yes


Notes.schema = new SimpleSchema
  _id:
    type: String
    regEx: SimpleSchema.RegEx.Id
    optional: yes
  parent:
    type: String
    regEx: SimpleSchema.RegEx.Id
    optional: yes
  title:
    type: String
    optional: yes
  createdAt:
    type: Date
    denyUpdate: yes
  updatedAt:
    type: Date
    optional: yes
  owner:
    type: String
    regEx: SimpleSchema.RegEx.Id
    optional: yes
  level:
    type: Number
    optional: yes
  children:
    type: Number
    optional: yes
  rank:
    type: Number
    optional: yes
    decimal: true
  due:
    type: Date
    optional: yes
  showChildren:
    type: Boolean
    optional: yes
  favorite:
    type: Boolean
    optional: yes
  favoritedAt:
    type: Date
    optional: yes
  admin:
    type: Boolean
    optional: yes
  body:
    type: String
    optional: yes

Notes.attachSchema Notes.schema

# This represents the keys from Notes objects that should be published
# to the client. If we add secret properties to Note objects, don't note
# them here to keep them private to the server.
Notes.publicFields =
  parent: 1
  title: 1
  createdAt: 1
  updatedAt: 1
  level: 1
  rank: 1
  due: 1
  showChildren: 1
  favorite: 1
  body: 1

# NOTE This factory has a name - do we have a code style for this?
#   - usually I've used the singular, sometimes you have more than one though, like
#   'note', 'emptyNote', 'checkedNote'
Factory.define 'note', Notes,
  text: ->
    faker.lorem.sentence()

  createdAt: ->
    new Date()

Notes.helpers
  note: ->
    Notes.findOne @noteId

  editableBy: (userId) ->
    @note().editableBy userId
