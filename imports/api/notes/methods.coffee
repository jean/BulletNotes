{ Meteor } = require 'meteor/meteor'
{ check } = require 'meteor/check'
{ Match } = require 'meteor/check'
{ Notes } = require './notes.coffee'
Dropbox = require('dropbox')

Meteor.methods
  'notes.insert': (title, rank = null, parent = null, shareKey = null) ->
    check title, String
    check rank, Match.Maybe(Number)
    # check parent, Match.Maybe(String)
    if !@userId || !Notes.isEditable parent, shareKey
      throw new (Meteor.Error)('not-authorized')

    if !rank
      rank = (Notes.find({parent: parent}).count() + 1) * 2
    level = 0
    parentNote = Notes.findOne(parent)
    if parentNote
      Notes.update parentNote._id,
        $inc: children: 1
        $set: showChildren: true
      level = parentNote.level + 1
    title = Notes.filterTitle title
    sharedNote = Notes.getSharedParent parent, shareKey
    if sharedNote
      owner = sharedNote.owner
    else
      owner = @userId
    Notes.insert
      title: title
      createdAt: new Date
      updatedAt: new Date
      rank: rank
      owner: owner
      parent: parent
      level: level
    , tx: true

  'notes.updateTitle': (id, title, shareKey = null) ->
    check title, Match.Maybe(String)
    if !title
      return false
    if !@userId || !Notes.isEditable id, shareKey
      throw new (Meteor.Error)('not-authorized')
    title = Notes.filterTitle title
    Notes.update id, {$set: {
      title: title
      updatedAt: new Date
    }}, tx: true
    return

  'notes.favorite': (id) ->
    if !@userId
      throw new (Meteor.Error)('not-authorized')
    note = Notes.findOne(id)
    Notes.update id, $set:
      favorite: !note.favorite
      favoritedAt: new Date
      updatedAt: new Date

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
      count = Notes.find({parent:note.parent_id}).count()
      Notes.update {
        _id: note.parent_id
      }, {$set: {
        showChildren: true
        children: count
      }}, tx: true
    tx.commit()

  'notes.updateBody': (id, body, shareKey = null) ->
    check body, String
    if !@userId || !Notes.isEditable id, shareKey
      throw new (Meteor.Error)('not-authorized')
    Notes.update { _id: id }, { $set: {body: body, updatedAt: new Date} }, tx: true

  'notes.remove': (id, shareKey = null) ->
    check id, String
    if !@userId || !Notes.isEditable id, shareKey
      throw new (Meteor.Error)('not-authorized')
    tx.start 'delete note'
    Meteor.call 'notes.removeRun', id
    tx.commit()

  'notes.removeRun': (id) ->
    children = Notes.find(parent: id)
    children.forEach (child) ->
      Meteor.call 'notes.removeRun', child._id
    note = Notes.findOne(id)
    Notes.update(note.parent, $inc:{children:-1})
    Notes.remove { _id: id }, tx: true

  'notes.outdent': (id, shareKey = null) ->
    if !@userId || !Notes.isEditable id, shareKey
      throw new (Meteor.Error)('not-authorized')
    note = Notes.findOne(id)
    old_parent = Notes.findOne(note.parent)
    Notes.update old_parent._id, $inc: children: -1
    new_parent = Notes.findOne(old_parent.parent)
    if new_parent
      Meteor.call 'notes.makeChild', note._id, new_parent._id, shareKey
    else
      # No parent left to go out to, set things to top level.
      children = Notes.find(parent: note._id)
      children.forEach (child) ->
        Notes.update child._id, $set: level: 1
      return Notes.update(id, $set:
        level: 0
        parent: null)

  'notes.makeChild': (id, parent, shareKey = null) ->
    check parent, String
    if !@userId || !Notes.isEditable id, shareKey
      throw new (Meteor.Error)('not-authorized')
    note = Notes.findOne(id)
    parent = Notes.findOne(parent)
    if !note or !parent or id == parent._id
      return false
    Notes.update parent._id,
      $inc: children: 1
      $set: showChildren: true
    Notes.update id, $set:
      rank: 0
      parent: parent._id
      level: parent.level + 1
      focusNext: 1
    children = Notes.find(parent: id)
    children.forEach (child) ->
      Meteor.call 'notes.makeChildRun', child._id, id, shareKey

  'notes.makeChildRun': (id, parent, shareKey = null) ->
    note = Notes.findOne(id)
    parent = Notes.findOne(parent)
    if !note or !parent or id == parent._id
      return false
    Notes.update parent._id,
      $inc: children: 1
      $set: showChildren: true
    Notes.update id, $set:
      rank: 0
      parent: parent._id
      level: parent.level + 1
    children = Notes.find(parent: id)
    children.forEach (child) ->
      Meteor.call 'notes.makeChildRun', child._id, id, shareKey

  'notes.showChildren': (id, show = true, shareKey = null) ->
    if !@userId || !Notes.isEditable id, shareKey
      throw new (Meteor.Error)('not-authorized')
    children = Notes.find(parent: id).count()
    Notes.update id, $set:
      showChildren: show
      children: children

  'notes.focus': (id) ->
    Notes.update id, $unset:
      focusNext

    
  'notes.export': (id = null, userId = null) ->
    if !userId
      userId = @userId
    topLevelNotes = Notes.find {
      parent: id
      owner: userId
    }, sort: rank: 1
    exportText = ''
    topLevelNotes.forEach (note) ->
      if !note.level
        note.level = 0
      spacing = new Array(note.level * 2).join(' ')
      exportText += spacing + '- ' + note.title.replace(/(\r\n|\n|\r)/gm, '') + '\n'
      if note.body
        exportText += spacing + '  "' + note.body + '"\n'
      exportText = exportText + Meteor.call('notes.export', note._id, userId)
    exportText

  'notes.dropbox': (userId) ->
    if !userId
      userId = @userId
    if Meteor.users.findOne(userId).profile && Meteor.users.findOne(userId).profile.dropbox_token
      exportText = Meteor.call('notes.export',null,userId)
      dbx = new Dropbox(accessToken: Meteor.users.findOne(userId).profile.dropbox_token)
      dbx.filesUpload(
        path: '/'+moment().format('YYYY-MM-DD-HH:mm:ss')+'.txt'
        contents: exportText).then((response) ->
        console.log response
      ).catch (error) ->
        console.error error

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
      Notes.update newNoteId, $set: showChildren: true, children: children.count()
      children.forEach (child) ->
        Meteor.call 'notes.duplicateRun', child._id, newNoteId

  'notes.share': (id, editable=false) ->
    chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.-"
    ii = 0
    key = ''
    while ii < 10
      key += chars.charAt(Math.floor(Math.random() * chars.length))
      ii++
    Notes.update id, $set: 
      shared: true
      shareKey: key
      sharedEditable: editable

  'notes.stopSharing': (id) ->
    Notes.update id, $set: 
      shared: false
      shareKey: null
