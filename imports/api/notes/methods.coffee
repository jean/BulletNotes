import { Meteor } from 'meteor/meteor'
import { _ } from 'meteor/underscore'
import { ValidatedMethod } from 'meteor/mdg:validated-method'
import { SimpleSchema } from 'meteor/aldeed:simple-schema'
import { DDPRateLimiter } from 'meteor/ddp-rate-limiter'
import childCountDenormalizer from './childCountDenormalizer.coffee'

import { Notes } from './notes.coffee'

export insert = new ValidatedMethod
  name: 'notes.insert'
  validate: Notes.simpleSchema().pick([
    'title'
    'rank'
    'parent'
  ]).validator
    clean: yes
    filter: no
  run: ({ title, rank, parent }) ->
    parent = Notes.findOne parent

    # if note.isPrivate() and note.userId isnt @userId
    #   throw new Meteor.Error 'notes.insert.accessDenied', 'Cannot add notes to a private note that is not yours'

    parentId = null
    level = 0

    if parent
      parentId = parent._id
      level = parent.level+1

    note =
      owner: @userId
      title: title
      parent: parentId
      rank: rank
      level: level
      createdAt: new Date()

    note = Notes.insert note#, tx: tx
    childCountDenormalizer.afterInsertNote parentId
    note

export favorite = new ValidatedMethod
  name: 'notes.favorite'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
  .validator
    clean: yes
    filter: no
  run: ({ noteId }) ->
    if !@userId
      throw new (Meteor.Error)('not-authorized')
    note = Notes.findOne(noteId)
    console.log note
    Notes.update noteId, $set:
      favorite: !note.favorite
      favoritedAt: new Date
      updatedAt: new Date

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

makeChildRun = (id, parent, shareKey = null) ->
  note = Notes.findOne(id)
  parent = Notes.findOne(parent)
  if !note or !parent or id == parent._id
    return false
  Notes.update parent._id, {
    $inc: children: 1
    $set: showChildren: true
  }, tx: true
  Notes.update id, { $set:
    rank: 0
    parent: parent._id
    level: parent.level + 1
  }, tx: true
  children = Notes.find(parent: id)
  children.forEach (child) ->
    makeChildRun child._id, id, shareKey

export makeChild = new ValidatedMethod
  name: 'notes.makeChild'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
    parent: Notes.simpleSchema().schema('parent')
    rank: Notes.simpleSchema().schema('rank')
    # shareKey: Notes.simpleSchema().schema('shareKey')
  .validator
    clean: yes
    filter: no
  run: ({ noteId, parent, rank }) ->
    # if !@userId || !Notes.isEditable id, shareKey
    #   throw new (Meteor.Error)('not-authorized')
    note = Notes.findOne(noteId)
    oldParent = Notes.findOne(note.parent)
    parent = Notes.findOne(parent)
    if !note or !parent or noteId == parent._id
      return false
    if !rank
      prevNote = Notes.findOne({parent: parent._id},sort: rank: -1)
      if prevNote
        rank = prevNote.rank+1
      else
        rank = 0
    tx.start 'note makeChild'
    if oldParent
      Notes.update oldParent._id, {
        $inc: children: -1
      }, tx: true
    Notes.update parent._id, {
      $inc: {children: 1}
      $set: {showChildren: true}
    }, tx: true
    Notes.update noteId, {$set:
      rank: rank
      parent: parent._id
      level: parent.level + 1
      focusNext: 1
    }, tx: true
    children = Notes.find(parent: noteId)
    children.forEach (child) ->
      makeChildRun child._id, noteId#, shareKey
    tx.commit()

removeRun = (id) ->
  children = Notes.find
    parent: id
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

    if !@userId #|| !Notes.isEditable id, shareKey
      throw new (Meteor.Error)('not-authorized')

    tx.start 'delete note'
    removeRun noteId
    tx.commit()

export outdent = new ValidatedMethod
  name: 'notes.outdent'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
  .validator
    clean: yes
    filter: no
  run: ({ noteId }) ->
    # if !@userId || !Notes.isEditable noteId, shareKey
    #   throw new (Meteor.Error)('not-authorized')
    note = Notes.findOne(noteId)
    old_parent = Notes.findOne(note.parent)
    new_parent = Notes.findOne(old_parent.parent)
    if new_parent
      Meteor.call 'notes.makeChild', {
        noteId: note._id
        parent: new_parent._id
        rank: old_parent.rank+1
        # shareKey
      }
    else
      # No parent left to go out to, set things to top level.
      children = Notes.find(parent: note._id)
      Notes.update old_parent._id, $inc: children: -1
      children.forEach (child) ->
        Notes.update child._id, $set: level: 1
      return Notes.update noteId, $set:
        level: 0
        parent: null
        focusNext: 1

export setShowChildren = new ValidatedMethod
  name: 'notes.setShowChildren'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
    show: type: Boolean
  .validator
    clean: yes
    filter: no
  run: ({ noteId, show = true }) ->
    # if !@userId || !Notes.isEditable id, shareKey
    #   throw new (Meteor.Error)('not-authorized')
    children = Notes.find(parent: noteId).count()
    Notes.update noteId, $set:
      showChildren: show
      children: children

Meteor.methods
  'notes.updateRanks': (notes, focusedNoteId = null, shareKey = null) ->
    if !@userId || !Notes.isEditable focusedNoteId, shareKey
      throw new (Meteor.Error)('not-authorized')

    # First save new parent IDs
    tx.start 'update note ranks'
    for ii, note of notes
      if note.parent_id
        noteParentId = note.parent_id
      # If we don't have a parentId, we're at the top level.
      # Use the focused note id
      else
        noteParentId = focusedNoteId

      Notes.update {
        _id: note.id
      }, {$set: {
        rank: note.left
        parent: noteParentId
      }}, tx: true
    # Now update the children count.
    # TODO: Don't do this here.
    for ii, note of notes
      count = Notes.find({parent:note.parent}).count()
      Notes.update {
        _id: note.parent_id
      }, {$set: {
        showChildren: true
        children: count
      }}, tx: true
    tx.commit()

  'notes.duplicate': (id, parentId = null) ->
    tx.start 'duplicate note'
    Meteor.call 'notes.duplicateRun', id
    tx.commit()

  'notes.duplicateRun': (id, parentId = null) ->
    console.log id, parentId
    note = Notes.findOne(id)
    if !note
      return false
    if !parentId
      parentId = note.parent
    newNoteId = Notes.insert
      title: note.title
      createdAt: new Date
      updatedAt: new Date
      rank: note.rank+.5
      owner: @userId
      parent: parentId
      level: note.level
    ,
      tx: true
      instant: true
    children = Notes.find parent: id
    if children
      Notes.update newNoteId,
        $set: showChildren: true,
        children: children.count()
      children.forEach (child) ->
        Meteor.call 'notes.duplicateRun', child._id, newNoteId



# Get note of all method names on Notes
NOTES_METHODS = _.pluck([
  # insert
  updateTitle
  remove
  makeChild
  outdent
  setShowChildren
  favorite
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