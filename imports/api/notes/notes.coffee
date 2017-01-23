{ Mongo } = require 'meteor/mongo'
Notes = exports.Notes = new Mongo.Collection 'notes'
sanitizeHtml = require('sanitize-html')

Notes.isEditable = (id, shareKey) ->
  sharedNote = Notes.getSharedParent id, shareKey
  # If we have a shareKey but can't find a valid sharedNote, aren't the sharedNote's owner,
  # or the sharedNote is not set to sharedEditable, don't allow.
  if shareKey && (!sharedNote || (sharedNote.owner != @userId && !sharedNote.sharedEditable))
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
    userId =  Meteor.userId()
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
