import { Mongo } from 'meteor/mongo'
import { Factory } from 'meteor/dburles:factory'
import SimpleSchema from 'simpl-schema'

sanitizeHtml = require('sanitize-html')

export Notes = new Mongo.Collection 'notes'
export NoteLogs = new Mongo.Collection 'tx.Transactions'

Notes.donePattern = /(#done|#complete|#finished)/gim

Notes.hashtagPattern = /(((^|\s)#)([a-z\d-]+))/gim

Notes.namePattern = /(((^|\s)@)([a-z\d-]+))/gim

Notes.isEditable = (id, shareKey) ->
  if !Meteor.user()
    return false

  if Notes.isOwner id
    return true
  else if !shareKey
    return false

  sharedNote = Notes.getSharedParent id, shareKey
  if sharedNote && sharedNote.sharedEditable
    return true

Notes.getSharedParent = (id, shareKey) ->
  note = Notes.findOne id
  while note && (note.shareKey != shareKey || note.shared == false)
    note = Notes.findOne note.parent
  if (note && note.shareKey == shareKey && note.shared == true)
    return note

Notes.isOwner = (id) ->
  note = Notes.findOne id
  note && Meteor.user()._id == note.owner

Notes.filterBody = (body) ->
  if !body
    return false
  body = emojione.toShort body

  sanitizeHtml body,
    allowedTags: [
      'b'
      'br'
      'i'
      'em'
      'strong'
    ]

Notes.filterTitle = (title) ->
  if !title
    return false
  title = title.replace(/(\r\n|\n|\r)/gm, '')
  title = emojione.toShort title

  sanitizeHtml title,
    allowedTags: [
      'b'
      'i'
      'em'
      'strong'
    ]

Notes.search = (search, userId = null, limit = 100) ->
  check search, Match.Maybe(String)
  query = {}
  projection = {
    limit: limit,
    sort: {
      childrenLastShown: 1
    }
  }
  if !userId
    userId =  Meteor.userId()
  if search.indexOf('last-changed:') == 0
    myRegexp = /last-changed:([0-9]+)([a-z]+)/gim
    match = myRegexp.exec(search)
    query =
      updatedAt: $gte: moment().subtract(match[1], match[2]).toDate()
      owner: userId
  else if search.indexOf('not-changed:') == 0
    myRegexp = /not-changed:([0-9]+)([a-z]+)/gim
    match = myRegexp.exec(search)
    query =
      updatedAt: $lte: moment().subtract(match[1], match[2]).toDate()
      owner: userId
  else if search.indexOf('not-viewed:') == 0
    myRegexp = /not-viewed:([0-9]+)([a-z]+)/gim
    match = myRegexp.exec(search)
    query =
      childrenLastShown: $lte: moment().subtract(match[1], match[2]).toDate()
      children: $gte: 1
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
    index: 1
  title:
    type: String
    optional: yes
  createdAt:
    type: Date
    denyUpdate: yes
  updatedAt:
    type: Date
    optional: yes
  deleted:
    type: Date
    optional: yes
    index: 1
  owner:
    type: String
    regEx: SimpleSchema.RegEx.Id
    optional: yes
    index: 1
  createdBy:
    type: String
    regEx: SimpleSchema.RegEx.Id
    optional: yes
  updatedBy:
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
    index: 1
  date:
    type: Date
    optional: yes
    index: 1
  showChildren:
    type: Boolean
    optional: yes
  favorite:
    type: Boolean
    optional: yes
    index: 1
  favoritedAt:
    type: Date
    optional: yes
  body:
    type: String
    optional: yes
  shared:
    type: Boolean
    optional: yes
  shareKey:
    type: String
    optional: yes
  sharedEditable:
    type: Boolean
    optional: yes
  sharedAt:
    type: Date
    optional: yes
  progress:
    type: Number
    optional: yes
  complete:
    type: Boolean
    optional: yes
    index: 1
  inbox:
    type: Boolean
    optional: yes
    index: 1
  showContent:
    type: Boolean
    optional: yes
  childrenLastShown:
    type: Date
    optional: yes
  updateCount:
    type: Number
    optional: yes
  childrenShownCount:
    type: Number
    optional: yes
  encrypted:
    type: Boolean
    optional: yes
  # True if this note is the note that the encryption was ran on.
  encryptedRoot:
    type: Boolean
    optional: yes
  transaction_id:
    type: SimpleSchema.RegEx.Id
    optional: true
  lat:
    type: Number
    optional: true
  lon:
    type: Number
    optional: true

Notes.attachSchema Notes.schema

# This represents the keys from Notes objects that should be published
# to the client. If we add secret properties to Note objects, don't note
# them here to keep them private to the server.
Notes.publicFields =
  parent: 1
  title: 1
  createdAt: 1
  createdBy: 1
  updatedAt: 1
  updatedBy: 1
  updateCount: 1
  level: 1
  rank: 1
  date: 1
  showChildren: 1
  favorite: 1
  body: 1
  progress: 1

Notes.helpers
  note: ->
    Notes.findOne @noteId

  editableBy: (userId) ->
    @note().editableBy userId
