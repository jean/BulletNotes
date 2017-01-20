{ Mongo } = require 'meteor/mongo'
Notes = exports.Notes = new Mongo.Collection 'notes'
# TODO: Heroku deploy didn't like this
# sanitizeHtml = require('sanitize-html')

Notes.filterTitle = (title) ->
  title = title.replace(/(\r\n|\n|\r)/gm, '')
  # sanitizeHtml title,
  #   allowedTags: [
  #     'b'
  #     'i'
  #     'em'
  #     'strong'
  #   ]

Notes.search = (search) ->
  check search, Match.Maybe(String)
  query = {}
  projection = limit: 100
  userId = @userId || Meteor.userId()
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
  Notes.find query, projection
