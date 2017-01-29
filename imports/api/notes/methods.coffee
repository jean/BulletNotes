import { Meteor } from 'meteor/meteor'
import { _ } from 'meteor/underscore'
import { ValidatedMethod } from 'meteor/mdg:validated-method'
import { SimpleSchema } from 'meteor/aldeed:simple-schema'
import { DDPRateLimiter } from 'meteor/ddp-rate-limiter'

import { Notes } from './notes.coffee'

export insert = new ValidatedMethod
  name: 'notes.insert'
  validate: Notes.simpleSchema().pick([
    'title'
    'rank'
    'level'
    'parent'
  ]).validator
    clean: yes
    filter: no
  run: ({ title, rank, level, parent }) ->
    note = Notes.findOne parent

    # if note.isPrivate() and note.userId isnt @userId
    #   throw new Meteor.Error 'notes.insert.accessDenied', 'Cannot add notes to a private note that is not yours'

    note =
      owner: @userId
      title: title
      parent: parent
      rank: rank
      level: level
      createdAt: new Date()

    Notes.insert note




export updateTitle = new ValidatedMethod
  name: 'notes.updateTitle'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
    title: Notes.simpleSchema().schema('title')
  .validator
    clean: yes
    filter: no
  run: ({ noteId, title }) ->
    # This is complex auth stuff - perhaps denormalizing a userId onto notes
    # would be correct here?
    note = Notes.findOne noteId

    # unless note.editableBy(@userId)
    #   throw new Meteor.Error 'notes.updateTitle.accessDenied', 'Cannot edit notes in a private note that is not yours'

    title = Notes.filterTitle title
    match = title.match(/#due-([0-9]+(-?))+/gim)
    if match
      date = match[0]
      Notes.update noteId, {$set: {
        title: title
        due: moment(date).format()
        updatedAt: new Date
      }}, tx: true
    else
      Notes.update noteId, {$set: {
        title: title
        updatedAt: new Date
      }}, tx: true


removeRun = (id) ->
  children = Notes.find(parent: id)
  children.forEach (child) ->
    removeRun child._id
  note = Notes.findOne(id)
  Notes.update(note.parent, $inc:{children:-1})
  Notes.remove { _id: id }, {tx: true, softDelete: true}

export remove = new ValidatedMethod
  name: 'notes.remove'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
  .validator
    clean: yes
    filter: no
  run: ({ noteId }) ->
    note = Notes.findOne noteId

    # unless note.editableBy(@userId)
    #   throw new Meteor.Error 'notes.remove.accessDenied', 'Cannot remove notes in a private note that is not yours'

    # if !@userId || !Notes.isEditable id, shareKey
    #   throw new (Meteor.Error)('not-authorized')

    tx.start 'delete note'
    removeRun noteId
    tx.commit()


# Get note of all method names on Notes
NOTES_METHODS = _.pluck([
  insert
  updateTitle
  remove
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