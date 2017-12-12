{ Template } = require 'meteor/templating'
{ ReactiveDict } = require 'meteor/reactive-dict'
{ Notes } = require '/imports/api/notes/notes.coffee'
{ Files } = require '/imports/api/files/files.coffee'

require './kanbanList.jade'
require '/imports/ui/components/kanbanListItem/kanbanListItem.coffee'

Template.kanbanList.helpers
  className: ->
    className = ''

    if !@title
      className += ' noTitle'
    className

  childNotes: ->
    Notes.find {
      parent: this._id
    }, sort: {
      complete: 1
      rank: 1
    }

  photo: () ->
    Meteor.subscribe 'files.note', @_id
    file = Files.findOne { noteId: @_id }
    if file
      file.data

  title: () ->
    if @title
      @title
    else
      '( Click to add a title )'

Template.kanbanList.events
  'click footer': (event, instance) ->
    parent = instance.data._id
    children = Notes.find { parent: parent }
    if children
      # Overkill, but, meh. It'll get sorted. Literally.
      rank = (children.count() * 40)
    else
      rank = 1
    Meteor.call 'notes.insert', {
      title: ''
      rank: rank
      parent: parent
      shareKey: FlowRouter.getParam('shareKey')
    }
    $(instance.firstNode).children(".kanbanChildNotes").animate({ scrollTop: $(instance.firstNode).children(".kanbanChildNotes")[0].scrollHeight }, 200)
    $(instance.firstNode).find(".title").last().focus()