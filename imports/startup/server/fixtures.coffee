{ Meteor } = require 'meteor/meteor'
{ Notes } = require '../../api/notes/notes.coffee'

Meteor.startup ->
  # if the Notes collection is empty
  if Notes.find().count() == 0
    data = [
      {
        title: 'Welcome to BulletNotes! #orange'
        rank: 1
        createdAt: new Date
      }
      {
        title: 'Sign in and have fun. 👍'
        rank: 2
        createdAt: new Date
      }
      {
        title: 'User Guide: https://github.com/NickBusey/BulletNotes/wiki #blue'
        body: 'There is plenty to do on BulletNotes. Get started now!'
        rank: 2
        createdAt: new Date
      }
    ]
    data.forEach (note) ->
      Notes.insert note
      return
  return
  