{ Template } = require 'meteor/templating'
{ ReactiveDict } = require 'meteor/reactive-dict'
{ Notes } = require '/imports/api/notes/notes.coffee'
{ Files } = require '/imports/api/files/files.coffee'

require './kanbanList.jade'

Template.kanbanList.onRendered ->
  Meteor.subscribe 'notes.children', this.data._id

Template.kanbanList.helpers
  childNotes: ->
    Notes.find {
      parent: this._id
    }, sort: rank: 1
