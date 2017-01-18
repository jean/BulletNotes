{ Meteor } = require 'meteor/meteor'
{ check } = require 'meteor/check'
{ Match } = require 'meteor/check'
{ Notes } = require './notes.coffee'

Meteor.methods
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
    title = title.replace(/(\r\n|\n|\r)/gm, '')
    if !@userId
      throw new (Meteor.Error)('not-authorized')
    Notes.update id, $set:
      title: title
      updatedAt: new Date
  'notes.star': (id) ->
    if !@userId
      throw new (Meteor.Error)('not-authorized')
    note = Notes.findOne(id)
    Notes.update id, $set:
      starred: !note.starred
      updatedAt: new Date
  'notes.updateRanks': (notes, parentId = null) ->
    for ii, note of notes
      if note.parentId
        noteParentId = note.parentId
      else 
        noteParentId = parentId
      Notes.update note.id, $set: {
        rank: note.left
        parent: noteParentId
      }
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
    Notes.update id, $set:
      body: body
      updatedAt: new Date
  'notes.remove': (id) ->
    check id, String
    if !@userId
      throw new (Meteor.Error)('not-authorized')
    children = Notes.find(parent: id)
    children.forEach (child) ->
      Meteor.call 'notes.remove', child._id
      return
    note = Notes.findOne(id)
    Notes.update(note.parent, $inc:{children:-1})
    Notes.remove { _id: id }, tx: true
    return
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
  'notes.email': (userId) ->
    if !userId
      userId = @userId
    exportText = Meteor.call('notes.export',null,userId)
    email = Meteor.users.findOne(userId).emails[0].address
    Email.send
      from: 'from@mailinator.com'
      to: email
      subject: new Date().toLocaleDateString() + ' Note Export'
      text: 'Below are your notes. You can paste the below into the "Import" section.\n------\n'+exportText

