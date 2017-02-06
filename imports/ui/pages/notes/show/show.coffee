{ Template } = require 'meteor/templating'
{ FlowRouter } = require 'meteor/kadira:flow-router'
{ Notes } = require '/imports/api/notes/notes.coffee'

import './show.jade'

# Components used inside the template
import '/imports/ui/pages/app-not-found.coffee'
import '/imports/ui/components/notes/notes.coffee'

{ noteRenderHold } = require '/imports/ui/launch-screen.js'

# Template.Notes_show.onRendered ->
#   this.autorun ->
#     if this.subscriptionsReady()
#       console.log 'release'
#       noteRenderHold.release()

Template.Notes_show.helpers
  noteIdArray: ->
    instance = Template.instance()
    noteId = FlowRouter.getParam('noteId')
    if Notes.findOne(noteId) then [ noteId ] else []
  noteArgs: (noteId) ->
    instance = Template.instance()
    # By finding the note with only the `_id` field set, we don't create a
    # dependency on the `note.incompleteCount`, and avoid
    # re-rendering the todos when it changes
    note = Notes.findOne(noteId, fields: _id: true)
    children = note and note.children()
    {
      childrenReady: instance.subscriptionsReady()
      note: ->
        Notes.findOne noteId
      children: children
    }
