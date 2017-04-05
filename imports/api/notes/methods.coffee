import { Meteor } from 'meteor/meteor'
import { _ } from 'meteor/underscore'
import { ValidatedMethod } from 'meteor/mdg:validated-method'
import SimpleSchema from 'simpl-schema'
import { DDPRateLimiter } from 'meteor/ddp-rate-limiter'
import { Random } from 'meteor/random'

import childCountDenormalizer from './childCountDenormalizer.coffee'
import rankDenormalizer from './rankDenormalizer.coffee'

import { Notes } from './notes.coffee'

export insert = new ValidatedMethod
  name: 'notes.insert'
  validate: new SimpleSchema
    title: Notes.simpleSchema().schema('title')
    rank: Notes.simpleSchema().schema('rank')
    parent: Notes.simpleSchema().schema('parent')
    shareKey: Notes.simpleSchema().schema('shareKey')
    isImport:
      type: Boolean
      optional: true
  .validator
    clean: yes
    filter: no
  run: ({ title, rank, parent, shareKey = null, isImport = false }) ->
    parent = Notes.findOne parent

    # if note.isPrivate() and note.userId isnt @userId
    #   throw new Meteor.Error 'notes.insert.accessDenied',
    # 'Cannot add notes to a private note that is not yours'

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

    # Only create a transaction if we are not importing.
    if isImport
      note = Notes.insert note
    else
      note = Notes.insert note, {tx: true}
      rankDenormalizer.updateSiblings parentId

    # This is pretty inefficient.
    # Should be smarter about it if isImport.
    childCountDenormalizer.afterInsertNote parentId

    note

export share = new ValidatedMethod
  name: 'notes.share'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
    editable:
      type: Boolean
      optional: true
  .validator
    clean: yes
    filter: no
  run: ({ noteId, editable = true }) ->
    if !@userId
      throw new (Meteor.Error)('not-authorized')
    Notes.update noteId, $set:
      shared: true
      shareKey: Random.id()
      sharedEditable: editable
      sharedAt: new Date
      updatedAt: new Date

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
    Notes.update noteId, $set:
      favorite: !note.favorite
      favoritedAt: new Date
      updatedAt: new Date

export updateBody = new ValidatedMethod
  name: 'notes.updateBody'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
    body: Notes.simpleSchema().schema('body')
    createTransaction:
      type: Boolean
      optional: true
  .validator
    clean: yes
    filter: no
  run: ({ noteId, body, createTransaction = true }) ->
    note = Notes.findOne noteId

    if body
      body = Notes.filterBody body
      Notes.update noteId, {$set: {
        body: body
        updatedAt: new Date
      }}, tx: createTransaction
    else
      Notes.update noteId, {$unset: {
        body: 1
      }}, tx: createTransaction

export setDueDate = new ValidatedMethod
  name: 'notes.setDueDate'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
    due: Notes.simpleSchema().schema('due')
    createTransaction:
      type: Boolean
      optional: true
  .validator
    clean: yes
    filter: no
  run: ({ noteId, due, createTransaction = true }) ->
    note = Notes.findOne(noteId)
    if note.owner != @userId
      return

    title = note.title.replace(/#due-([0-9]+(-?))+/gim,'')
    title = title.trim()
    title = title+' #due-'+moment(due).format('YYYY-MM-DD')
    Notes.update noteId, $set:
      due: due,
      title: title
      updatedAt: new Date

export stopSharing = new ValidatedMethod
  name: 'notes.stopSharing'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
  .validator
    clean: yes
    filter: no
  run: ({ noteId }) ->
    if !Notes.isOwner noteId
      throw new (Meteor.Error)('not-authorized')

    Notes.update noteId, $unset:
      shared: 1
      shareKey: 1

export updateTitle = new ValidatedMethod
  name: 'notes.updateTitle'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
    title: Notes.simpleSchema().schema('title')
    shareKey: Notes.simpleSchema().schema('shareKey')
  .validator
    clean: yes
    filter: no
  run: ({ noteId, title, shareKey = null }) ->
    note = Notes.findOne noteId

    if !Notes.isEditable noteId, shareKey
      throw new (Meteor.Error)('not-authorized')

    title = Notes.filterTitle title
    if title
      match = title.match(/#due-([0-9]+(-?))+/gim)
    else
      title = ''
    if match
      date = match[0]
      Notes.update noteId, {$set: {
        due: moment(date).format()
        updatedAt: new Date
      }}, tx: true

    Notes.update noteId, {$set: {
      title: title
      updatedAt: new Date
    }}, tx: true

    pattern = /#pct-([0-9]+)/gim
    match = pattern.exec note.title
    if match
      Notes.update noteId, {$set: {
        progress: match[1]
        updatedAt: new Date
      }}
    else
      # If there is not a defined percent tag (e.g., #pct-20)
      # then calculate the #done rate of notes
      notes = Notes.find({ parent: note.parent })
      total = 0
      done = 0
      notes.forEach (note) ->
        total++
        if note.title
          match = note.title.match Notes.donePattern
          if match
            done++
      Notes.update note.parent, {$set: {
        progress: Math.round((done/total)*100)
        updatedAt: new Date
      }}

export makeChild = new ValidatedMethod
  name: 'notes.makeChild'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
    parent: Notes.simpleSchema().schema('parent')
    shareKey: Notes.simpleSchema().schema('shareKey')
    upperSibling: Notes.simpleSchema().schema('_id')
    rank: Notes.simpleSchema().schema('rank')
  .validator
    clean: yes
    filter: no
  run: ({ noteId, parent = null, shareKey = null, upperSibling = null, rank = null }) ->
    if !@userId || !Notes.isEditable noteId, shareKey
      throw new (Meteor.Error)('not-authorized')

    note = Notes.findOne(noteId)
    if !note
      throw new (Meteor.Error)('note-not-found')
    oldParent = Notes.findOne(note.parent)
    parent = Notes.findOne(parent)
    if upperSibling
      upperSibling = Notes.findOne(upperSibling)
      rank = upperSibling.rank + 1

    if !rank
      rank = 1

    tx.start 'note makeChild'
    parentId = null
    level = 0
    if parent
      Notes.update parent._id, {
        $set:
          showChildren: true
          updatedAt: new Date
      }, tx: true
      parentId = parent._id

    Notes.update noteId, {$set:
      rank: rank
      parent: parentId
    }, {tx: true }
    tx.commit()

    rankDenormalizer.updateSiblings parentId

    if oldParent
      childCountDenormalizer.afterInsertNote oldParent._id
    if parent
      childCountDenormalizer.afterInsertNote parent._id

removeRun = (id) ->
  children = Notes.find
    parent: id
  children.forEach (child) ->
    removeRun child._id
  note = Notes.findOne(id)
  Notes.remove { _id: id }, {tx: true, softDelete: true, instant: true }

export remove = new ValidatedMethod
  name: 'notes.remove'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
    shareKey: Notes.simpleSchema().schema('shareKey')
  .validator
    clean: yes
    filter: no
  run: ({ noteId, shareKey = null }) ->
    note = Notes.findOne noteId

    if !@userId || !Notes.isEditable noteId, shareKey
      throw new (Meteor.Error)('not-authorized')

    if Notes.find({owner:@userId}).count() == 1
      throw new (Meteor.Error)('Can\'t delete last note')

    tx.start 'delete note'
    removeRun noteId
    childCountDenormalizer.afterInsertNote note.parent
    tx.commit()

export outdent = new ValidatedMethod
  name: 'notes.outdent'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
    shareKey: Notes.simpleSchema().schema('shareKey')
  .validator
    clean: yes
    filter: no
  run: ({ noteId, shareKey = null }) ->
    if !@userId || !Notes.isEditable noteId, shareKey
      throw new (Meteor.Error)('not-authorized')
    note = Notes.findOne(noteId)
    old_parent = Notes.findOne(note.parent)
    new_parent = Notes.findOne(old_parent.parent)
    if new_parent
      Meteor.call 'notes.makeChild', {
        noteId: note._id
        parent: new_parent._id
        rank: old_parent.rank + 1
        shareKey
      }
    else
      # No parent left to go out to, set things to top level.
      children = Notes.find(parent: note._id)
      children.forEach (child) ->
        Notes.update child._id, $set: level: 1
      Notes.update noteId, $set:
        focusNext: true
        parent: null
        rank: old_parent.rank+1
    childCountDenormalizer.afterInsertNote old_parent._id

export setShowContent = new ValidatedMethod
  name: 'notes.setShowContent'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
    showContent: type: Boolean
  .validator
    clean: yes
  run: ({ noteId, showContent = true, shareKey = null }) ->
    if !@userId || !Notes.isEditable noteId, shareKey
      throw new (Meteor.Error)('not-authorized')

    Notes.update noteId, $set:
      showContent: showContent
      updatedAt: new Date

export setShowChildren = new ValidatedMethod
  name: 'notes.setShowChildren'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
    show: type: Boolean
  .validator
    clean: yes
  run: ({ noteId, show = true, shareKey = null }) ->
    if !@userId || !Notes.isEditable noteId, shareKey
      throw new (Meteor.Error)('not-authorized')

    Notes.update noteId, $set:
      showChildren: show
      updatedAt: new Date

    childCountDenormalizer.afterInsertNote noteId

export focus = new ValidatedMethod
  name: 'notes.focus'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
  .validator
    clean: yes
  run: ({noteId}) ->
    if !@userId
      throw new (Meteor.Error)('not-authorized')
    Notes.update {_id: noteId}, {$unset:{focusNext: 1}}

Meteor.methods

  'notes.duplicate': (id, parentId = null) ->
    tx.start 'duplicate note'
    Meteor.call 'notes.duplicateRun', id
    tx.commit()

  'notes.duplicateRun': (id, parentId = null) ->
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
  updateTitle
  updateBody
  remove
  makeChild
  outdent
  setShowChildren
  setShowContent
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
