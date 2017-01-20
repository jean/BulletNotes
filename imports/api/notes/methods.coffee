{ Meteor } = require 'meteor/meteor'
{ check } = require 'meteor/check'
{ Match } = require 'meteor/check'
{ Notes } = require './notes.coffee'
Dropbox = require('dropbox')

Meteor.methods
  'users.setDropboxOauth': (access_token) ->
    check access_token, String
    console.log access_token
    Meteor.users.update {_id:@userId}, {$set:{"profile.dropbox_token":access_token}}

  'notes.insert': (title, rank = null, parent = null) ->
    check title, String
    check rank, Match.Maybe(Number)
    check parent, Match.Maybe(String)
    if !@userId
      throw new (Meteor.Error)('not-authorized')
    if !rank
      rank = Notes.find(parent: parent).count() + 1
    level = 0
    parentNote = Notes.findOne(parent)
    if parentNote
      Notes.update parentNote._id,
        $inc: children: 1
        $set: showChildren: true
      level = parentNote.level + 1
    title = title.replace(/(\r\n|\n|\r)/gm, '')
    Notes.insert
      title: title
      createdAt: new Date
      updatedAt: new Date
      rank: rank
      owner: @userId
      parent: parent
      level: level
  'notes.updateTitle': (id, title) ->
    check title, Match.Maybe(String)
    if title
      title = title.replace(/(\r\n|\n|\r)/gm, '')
    if !@userId
      throw new (Meteor.Error)('not-authorized')
    Notes.update {_id:id}, {$set: {
      title: title
      updatedAt: new Date
      }}, tx: true
  'notes.favorite': (id) ->
    if !@userId
      throw new (Meteor.Error)('not-authorized')
    note = Notes.findOne(id)
    Notes.update id, $set:
      favorite: !note.favorite
      favoritedAt: new Date
      updatedAt: new Date
  'notes.updateRanks': (notes, focusedNoteId = null) ->
    # First save new parent IDs
    for ii, note of notes
      if note.parent_id
        noteParentId = note.parent_id
      # If we don't have a parentId, we're at the top level.
      # Use the focused note id
      else 
        noteParentId = focusedNoteId

      Notes.update note.id, $set: {
        rank: note.left
        parent: noteParentId
      }

    # Now update the children count.
    # TODO: Don't do this here.
    for ii, note of notes
      count = Notes.find({parent:note.parent_id}).count()
      Notes.update note.parent_id, $set: {
        showChildren: true
        children: count
      }
  'notes.updateBody': (id, body) ->
    check body, String
    if !@userId
      throw new (Meteor.Error)('not-authorized')
    Notes.update { _id: id }, { $set: {body: body, updatedAt: new Date} }, tx: true
  'notes.remove': (id) ->
    check id, String
    if !@userId
      throw new (Meteor.Error)('not-authorized')

    tx.start 'delete note'
    children = Notes.find(parent: id)
    children.forEach (child) ->
      Meteor.call 'notes.remove', child._id
    note = Notes.findOne(id)
    Notes.update(note.parent, $inc:{children:-1})
    Notes.remove { _id: id }, tx: true
    tx.commit()
  'notes.outdent': (id) ->
    if !@userId
      throw new (Meteor.Error)('not-authorized')
    note = Notes.findOne(id)
    old_parent = Notes.findOne(note.parent)
    Notes.update old_parent._id, $inc: children: -1
    new_parent = Notes.findOne(old_parent.parent)
    if new_parent
      Meteor.call 'notes.makeChild', note._id, new_parent._id
    else
      # No parent left to go out to, set things to top level.
      children = Notes.find(parent: note._id)
      children.forEach (child) ->
        Notes.update child._id, $set: level: 1
        return
      return Notes.update(id, $set:
        level: 0
        parent: null)
    return
  'notes.makeChild': (id, parent) ->
    `var parent`
    check parent, String
    if !@userId
      throw new (Meteor.Error)('not-authorized')
    note = Notes.findOne(id)
    parent = Notes.findOne(parent)
    console.log parent, '---', note
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
      Meteor.call 'notes.makeChild', child._id, id
      return
    return
  'notes.showChildren': (id, show = true) ->
    if !@userId
      throw new (Meteor.Error)('not-authorized')
    children = Notes.find(parent: id).count()
    Notes.update id, $set:
      showChildren: show
      children: children
    return
  'notes.export': (id = null, userId = null) ->
    if !userId
      userId = @userId
    topLevelNotes = Notes.find(
      parent: id
      owner: userId)
    exportText = ''
    topLevelNotes.forEach (note) ->
      if !note.level
        note.level = 0
      spacing = new Array(note.level * 2).join(' ')
      exportText += spacing + '- ' + note.title.replace(/(\r\n|\n|\r)/gm, '') + '\n'
      if note.body
        exportText += spacing + '  "' + note.body + '"\n'
      exportText = exportText + Meteor.call('notes.export', note._id, userId)
      return
    exportText
  'notes.dropbox': (userId) ->
    if !userId
      userId = @userId
    if Meteor.users.findOne(userId).profile.dropbox_token
      exportText = Meteor.call('notes.export',null,userId)
      dbx = new Dropbox(accessToken: Meteor.users.findOne(userId).profile.dropbox_token)
      dbx.filesUpload(
        path: '/'+moment().format('YYYY-MM-DD-HH:mm:ss')+'.txt'
        contents: exportText).then((response) ->
        console.log response
      ).catch (error) ->
        console.error error
