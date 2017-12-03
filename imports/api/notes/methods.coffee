import { Meteor } from 'meteor/meteor'
import { _ } from 'meteor/underscore'
import { ValidatedMethod } from 'meteor/mdg:validated-method'
import SimpleSchema from 'simpl-schema'
import { DDPRateLimiter } from 'meteor/ddp-rate-limiter'
import { Random } from 'meteor/random'

import rankDenormalizer from './rankDenormalizer.coffee'
import childCountDenormalizer from './childCountDenormalizer.coffee'
sanitizeHtml = require('sanitize-html')

import { Notes } from './notes.coffee'

export insert = new ValidatedMethod
  name: 'notes.insert'
  validate: new SimpleSchema
    title: Notes.simpleSchema().schema('title')
    rank: Notes.simpleSchema().schema('rank')
    parent: Notes.simpleSchema().schema('parent')
    shareKey: Notes.simpleSchema().schema('shareKey')
    complete: Notes.simpleSchema().schema('complete')
    showChildren: Notes.simpleSchema().schema('showChildren')
    ownerId: Notes.simpleSchema().schema('owner')
    isImport:
      type: Boolean
      optional: true
  .validator
    clean: yes
    filter: no
  run: ({ title, rank, parent, shareKey = null, isImport = false, complete = false, showChildren = false, ownerId = null }) ->
    parent = Notes.findOne parent

    # if note.isPrivate() and note.userId isnt @userId
    #   throw new Meteor.Error 'notes.insert.accessDenied',
    # 'Cannot add notes to a private note that is not yours'

    if !Meteor.isServer
      if !Meteor.user()
        throw new Meteor.Error 'not-authorized',
          'Please login'

      if parentId && !Notes.isEditable parentId, shareKey
        throw new Meteor.Error 'not-authorized',
          'Cannot edit this note'

    if @userId
      ownerId = @userId

    noteCount = Notes.find
      owner: owner
      deleted: {$exists: false}
    .count()

    referralCount = 0
    owner = Meteor.users.findOne ownerId
    if owner.referralCount > 0
      referralCount = owner.referralCount

    if !owner.isAdmin && noteCount >= Meteor.settings.public.noteLimit * (referralCount + 1)
      throw new (Meteor.Error)('Maximum number of notes reached.')

    parentId = null

    if parent
      parentId = parent._id

    sharedParent = Notes.getSharedParent parentId, shareKey
    if sharedParent
      ownerId = sharedParent.owner

    note =
      owner: ownerId
      title: title
      parent: parentId
      rank: rank
      createdAt: new Date()
      complete: complete
      showChildren: showChildren
      createdBy: ownerId

    # Only create a transaction if we are not importing.
    if isImport
      note = Notes.insert note
    else
      note = Notes.insert note, {tx: true}

    Meteor.defer ->
      childCountDenormalizer.afterInsertNote parentId

    Meteor.users.update ownerId,
      {$inc:{"notesCreated":1}}

    if Meteor.isClient
      Template.App_body.recordEvent 'newNote', owner: ownerId

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
  run: ({ noteId, editable = false }) ->
    if !@userId
      throw new (Meteor.Error)('not-authorized')
    Notes.update noteId, $set:
      shared: true
      shareKey: Random.id()
      sharedEditable: editable
      sharedAt: new Date

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

    bodyHasContent = true
    sanitizedBody = sanitizeHtml body,
      allowedTags: []
    sanitizedBody = sanitizedBody.replace(/(\r\n|\n|\r|\s)/gm, '')

    if sanitizedBody.length < 1
      bodyHasContent = false

    if body && bodyHasContent
      body = Notes.filterBody body
      Notes.update noteId, {$set: {
        body: body
        updatedAt: new Date
      },$inc: {
        updateCount: 1
      }}, tx: createTransaction
    else
      Notes.update noteId, {$unset: {
        body: 1
      }, $set: {
        showContent: false
      }}, tx: createTransaction

export setDueDate = new ValidatedMethod
  name: 'notes.setDueDate'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
    date:
      type: String
    createTransaction:
      type: Boolean
      optional: true
  .validator
    clean: yes
    filter: no
  run: ({ noteId, date, createTransaction = true }) ->
    note = Notes.findOne(noteId)
    if note.owner != @userId
      return

    console.log "Got date date: ", date

    title = note.title.replace(/#(date|due)-([0-9]+(-?))+/gim,'')
    title = title.trim()
    title = title+' #date-'+date
    Notes.update noteId, $set:
      date: date
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


export setEncrypted = new ValidatedMethod
  name: 'notes.setEncrypted'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
    encrypted: Notes.simpleSchema().schema('encrypted')
    encryptedRoot: Notes.simpleSchema().schema('encryptedRoot')
    shareKey: Notes.simpleSchema().schema('shareKey')
  .validator
    clean: yes
    filter: no
  run: ({ noteId, encrypted, encryptedRoot = false, shareKey = null }) ->
    note = Notes.findOne noteId

    if !Notes.isEditable noteId, shareKey
      throw new (Meteor.Error)('not-authorized')

    Notes.update noteId, {$set: {
      encrypted: encrypted
      encryptedRoot: encryptedRoot
    }}, tx: true


export updateTitle = new ValidatedMethod
  name: 'notes.updateTitle'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
    title: Notes.simpleSchema().schema('title')
    shareKey: Notes.simpleSchema().schema('shareKey')
    createTransaction:
      type: Boolean
      optional: true
  .validator
    clean: yes
    filter: no
  run: ({ noteId, title, shareKey = null, createTransaction = true }) ->
    note = Notes.findOne noteId

    if !Notes.isEditable noteId, shareKey
      throw new (Meteor.Error)('not-authorized')

    if createTransaction
      tx.start 'Update Note Title', { context:{ noteId: noteId } }
    
    title = Notes.filterTitle title
    if title
      match = title.match(/#date-([0-9]+(-?))+/gim)
    else
      title = ''

    if match
      date = match[0]
      Notes.update noteId, {$set: {
        date: moment(date).format()
      },$inc: {
        updateCount: 1
      }}
    else
      Notes.update noteId, {$unset: {
        date: 1
      },$inc: {
        updateCount: 1
      }}

    complete = false
    if title.match Notes.donePattern
      complete = true

    Notes.update noteId, {$set: {
      title: title
      updatedAt: new Date
      updatedBy: @userId
      complete: complete
    }}, tx: createTransaction

    if createTransaction
      tx.commit()

    Meteor.defer ->
      pattern = /#pct-([0-9]+)/gim
      match = pattern.exec note.title
      if match
        Notes.update noteId, {$set: {
          progress: match[1]
        }}
      else
        # If there is not a defined percent tag (e.g., #pct-20)
        # then calculate the #done rate of notes
        notes = Notes.find({ parent: note.parent, deleted: {$exists: false} })
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
        }}

    Meteor.call 'tags.updateNoteTags',
      noteId: note._id

export makeChild = new ValidatedMethod
  name: 'notes.makeChild'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
    parent: Notes.simpleSchema().schema('parent')
    shareKey: Notes.simpleSchema().schema('shareKey')
    upperSibling: Notes.simpleSchema().schema('_id')
    rank: Notes.simpleSchema().schema('rank')
    expandParent:
      type: Boolean
      optional: true
  .validator
    clean: yes
    filter: no
  run: ({ noteId, parent = null, shareKey = null, upperSibling = null, rank = null, expandParent = true }) ->
    if !@userId || !Notes.isEditable noteId, shareKey
      throw new (Meteor.Error)('not-authorized')
    console.log "Rank: ", rank
    note = Notes.findOne(noteId)
    if !note
      throw new (Meteor.Error)('note-not-found')
    oldParent = Notes.findOne(note.parent)
    if parent
      parent = Notes.findOne(parent)

    if rank == null
      if upperSibling
        upperSibling = Notes.findOne(upperSibling)
        rank = upperSibling.rank + 1
      else
        if parent
          rank = Notes.find({parent:parent._id}).count() * 2

    if rank == null
      rank = 1

    tx.start 'Move Note'
    parentId = null
    level = 0
    if parent
      parentId = parent._id

    if expandParent
      Notes.update parentId, {$set:
        showChildren: true
        childrenLastShown: new Date
      }, {tx: true }
    console.log "Rank: ", rank
    Notes.update noteId, {$set:
      rank: rank
      parent: parentId
    }, {tx: true }
    tx.commit()

    if oldParent
      childCountDenormalizer.afterInsertNote oldParent._id
    if parent
       childCountDenormalizer.afterInsertNote parent._id

    rankDenormalizer.updateSiblings parentId

removeRun = (note) ->
  Notes.remove { _id: note._id }, { tx: true, softDelete: true }

  children = Notes.find
    parent: note._id
  children.forEach (child) ->
    removeRun child

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

    tx.start 'delete note'
    removeRun note
    tx.commit()

    childCountDenormalizer.afterInsertNote note.parent

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

export setChildrenLastShown = new ValidatedMethod
  name: 'notes.setChildrenLastShown'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
  .validator
    clean: yes
  run: ({ noteId }) ->
    if !@userId
      throw new (Meteor.Error)('not-authorized')

    Notes.update noteId, $set:
      childrenLastShown: new Date

    Notes.update noteId, $inc:
      childrenShownCount: 1

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
      childrenLastShown: new Date


export duplicate = new ValidatedMethod
  name: 'notes.duplicate'
  validate: new SimpleSchema
    noteId: Notes.simpleSchema().schema('_id')
    shareKey: Notes.simpleSchema().schema('shareKey')
  .validator
    clean: yes
    filter: no
  run: ({ noteId, shareKey = null }) ->
    if !@userId || !Notes.isEditable noteId, shareKey
      throw new (Meteor.Error)('not-authorized')
    duplicateRun @userId, noteId

duplicateRun = (userId, id, parentId = null) ->
  note = Notes.findOne(id)
  if !note
    return false
  if !parentId
    parentId = note.parent
  newNoteId = Notes.insert
    title: note.title
    createdAt: new Date
    rank: note.rank+.5
    owner: userId
    parent: parentId
    level: note.level
    body: note.body
    complete: false

  Meteor.users.update {_id:@userId},
    {$inc:{"notesCreated":1}}

  children = Notes.find
    parent: id
    deleted: {$exists: false}
  if children
    Notes.update newNoteId,
      $set: showChildren: true,
      children: children.count()
    children.forEach (child) ->
      duplicateRun userId, child._id, newNoteId

NOTES_METHODS = _.pluck([
  updateBody
  remove
  makeChild
  outdent
  setShowChildren
  setShowContent
  favorite
  duplicate
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
