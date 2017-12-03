import { Meteor } from 'meteor/meteor'
import { _ } from 'meteor/underscore'
import { ValidatedMethod } from 'meteor/mdg:validated-method'
import SimpleSchema from 'simpl-schema'
import { DDPRateLimiter } from 'meteor/ddp-rate-limiter'
Dropbox = require('dropbox')

import rankDenormalizer from '/imports/api/notes/rankDenormalizer.coffee'
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
      spacing = new Array(level * 5).join(' ')
      exportText += spacing + '- '
      if note.title
        exportText += note.title
      exportText += '\n'
      if note.body
        exportText += spacing + '  "' + note.body + '"\n'
      exportText = exportText + notesExport.call {
        noteId: note._id
        userId: userId
        level: level+1
      }
    exportText

export dropboxExport = new ValidatedMethod
  name: 'notes.dropboxExport'
  validate: null
  run: () ->
    user = Meteor.user()
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
        path: '/BulletNotes'+moment().format('-YYYY-MM-DD')+'.txt'
        contents: exportText).then((response) ->
          console.log response
      ).catch (error) ->
        console.error error
        throw new (Meteor.Error)(error)
    else
      throw new (Meteor.Error)('No linked Dropbox account')

export dropboxNightly = new ValidatedMethod
  name: 'notes.dropboxNightly'
  validate: null
  run: () ->
    users = Meteor.users.find({
      isPro:true
    })
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
          path: '/BulletNotes'+moment().format('-YYYY-MM-DD')+'.txt'
          contents: exportText).then((response) ->
            console.log response
        ).catch (error) ->
          console.error error

export inbox = new ValidatedMethod
  name: 'notes.inbox'
  validate: new SimpleSchema
    title: Notes.simpleSchema().schema('title')
    body: Notes.simpleSchema().schema('body')
    userId: Notes.simpleSchema().schema('_id')
    parentId:
      type: String
      optional: true
  .validator
    clean: yes
    filter: no
  # userId has already been translated from apiKey by notes/routes by the time it gets here
  run: ({ title, body, userId, parentId = null }) ->
    # If we have a parent note to put it under, use that. But make sure we have write permissions.
    if parentId
      note = Notes.findOne
        owner: userId
        _id: parentId

      if !note        
        # No permission, or no note. Just quit.
        false

    # We don't have a specific note to put this under, put it in the Inbox
    else
      inbox = Notes.findOne
        owner: userId
        inbox: true
        deleted: {$exists:false}

      # If there is not an existing Inbox note, create one.
      if !inbox
        parentId = Notes.insert
          title: ":inbox_tray: <b>Inbox</b>"
          createdAt: new Date()
          owner: userId
          inbox: true
          showChildren: true
          complete: false

      # Otherwise, use the existing inbox
      else
        parentId = inbox._id

    if parentId
      noteId = Notes.insert
        title: title
        body: body
        parent: parentId
        owner: userId
        createdAt: new Date()
        rank: 0
        complete: false

      Meteor.users.update userId,
        {$inc:{"notesCreated":1}}

      Meteor.defer ->
        rankDenormalizer.updateSiblings parentId
    
      return noteId

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

# We don't add this to to rate limiter because imports hit it a bunch. Hence the defer.
export denormalizeChildCount = new ValidatedMethod
  name: 'notes.denormalizeChildCount'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
  .validator
    clean: yes
    filter: no
  run: ({ noteId }) ->
    Meteor.defer ->
      childCountDenormalizer.afterInsertNote noteId

# Get note of all method names on Notes
NOTES_METHODS = _.pluck([
  notesExport
  dropboxExport
  dropboxNightly
  summary
  inbox
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
