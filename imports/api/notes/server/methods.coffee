import { Meteor } from 'meteor/meteor'
import { _ } from 'meteor/underscore'
import { ValidatedMethod } from 'meteor/mdg:validated-method'
import SimpleSchema from 'simpl-schema'
import { DDPRateLimiter } from 'meteor/ddp-rate-limiter'
Dropbox = require('dropbox')

import childCountDenormalizer from '/imports/api/notes/childCountDenormalizer.coffee'

import { Notes } from '/imports/api/notes/notes.coffee'

export notesExport = new ValidatedMethod
  name: 'notes.export'
  validate: new SimpleSchema
    noteId:
      type: String
      optional: true
    userId: Notes.simpleSchema().schema('owner')
    level: Notes.simpleSchema().schema('level')
  .validator
    clean: yes
    filter: no
  run: ({ noteId = null, userId = null, level = 0 }) ->
    if !userId
      userId = @userId
    if !userId
      throw new (Meteor.Error)('not-authorized - no userId')

    topLevelNotes = Notes.find {
      parent: noteId
      owner: userId
      deleted: {$exists: false}
    }, sort: rank: 1
    exportText = ''
    topLevelNotes.forEach (note) ->
      if note.title
        spacing = new Array(level * 5).join(' ')
        exportText += spacing + '- ' +
          note.title.replace(/(\r\n|\n|\r)/gm, '') + '\n'
        if note.body
          exportText += spacing + '  "' + note.body + '"\n'
        exportText = exportText + notesExport.call {
          noteId: note._id
          userId: userId
          level: level+1
        }
    exportText

export dropbox = new ValidatedMethod
  name: 'notes.dropbox'
  validate: null
  run: () ->
    users = Meteor.users.find({})
    users.forEach (user) ->
      if (
        user.profile &&
        user.profile.dropbox_token
      )
        exportText = notesExport.call
          noteId: null
          userId: user._id
        dbx = new Dropbox(
          accessToken: user.profile.dropbox_token
        )
        dbx.filesUpload(
          path: '/'+moment().format('YYYY-MM-DD-HH:mm:ss')+'.txt'
          contents: exportText).then((response) ->
            console.log response
        ).catch (error) ->
          console.error error

export summary = new ValidatedMethod
  name: 'notes.summary'
  validate: null
  run: () ->
    users = Meteor.users.find({})
    users.forEach (user) ->
      if user.emails
        email = user.emails[0].address
        notes = Notes.search 'last-changed:24h', user._id
        SSR.compileTemplate( 'Email_summary', Assets.getText( 'email/summary.html' ) )
        html = SSR.render 'Email_summary',
          site_url: Meteor.absoluteUrl()
          notes: notes
        Email.send({
          to: email,
          from: "BulletNotes.io <admin@bulletnotes.io>",
          subject: "Daily Activity Summary",
          html: html
        })


# Get note of all method names on Notes
NOTES_METHODS = _.pluck([
  notesExport
  dropbox
  summary
], 'name')

if Meteor.isServer
  # Only allow 5 notes operations per connection per second
  DDPRateLimiter.addRule {
    name: (name) ->
      _.contains NOTES_METHODS, name

    # Rate limit per connection ID
    connectionId: ->
      yes

  }, 5, 1000