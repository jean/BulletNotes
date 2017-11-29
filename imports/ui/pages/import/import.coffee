{ Template } = require 'meteor/templating'
{ Notes } = require '/imports/api/notes/notes.coffee'

import {
  insert,
  updateBody
} from '/imports/api/notes/methods.coffee'

require './import.jade'

Template.Notes_import.onRendered ->
  NProgress.done()
  $(".mdl-layout__content").animate({ scrollTop: 0 }, 500)

Template.Notes_import.events
  'submit .importForm': (event, instance) ->
    NProgress.configure({ trickle: false })
    NProgress.start()
    event.preventDefault()
    data = {}
    textarea = $(event.currentTarget).find('textarea').get(0)
    $(".mdl-layout__content").animate({ scrollTop: 0 }, 200)
    data.importLines = textarea.value.split('\n')
    textarea.value = ''
    data.prevLevel = 0
    data.prevParents = []
    data.levelRanks = []
    Template.Notes_import.import data

Template.Notes_import.import = (data, ii = 0, lastNote = null) ->
  line = data.importLines[ii]
  NProgress.set(ii/data.importLines.length)
  if (data.importLines.length - 1 == ii)
    NProgress.done()
  if !line || line.trim().substr(0, 1) != '-'
    # Invalid line, skip it move to the next.
    Template.Notes_import.import data, ii + 1, lastNote
    return
  leadingSpaceCount = line.match(/^(\s*)/)[1].length
  level = leadingSpaceCount / 4
  parent = null
  if level > 0
    # Calculate parent
    if level > data.prevLevel
      # This is a new depth, look at the last added note
      parent = lastNote
      data.prevParents[level] = parent
    else
      #  We have moved back out to a higher level
      parent = data.prevParents[level]
  data.prevLevel = level
  if data.levelRanks[level]
    data.levelRanks[level]++
  else
    data.levelRanks[level] = 1
  title = line.substr(2 + level * 4)
  # Replace Workflowy [COMPLETE] tag with a #done tag.
  title = title.replace(/(\[COMPLETE\])/,'#done')
  # Check if the next line is a body
  nextLine = data.importLines[ii + 1]
  body = null
  if nextLine and nextLine.trim().substr(0, 1) == '"'
    body = nextLine.trim().substr(1)
    body = body.substr(0, body.length-1)

  insert.call {
    title: title
    rank: data.levelRanks[level]
    parent: parent
    isImport: true
  }, (err, res) ->

    if !level
      FlowRouter.go('/')

    # Wrapping the following calls in these short Timeouts prevents browser lockup
    if body
      updateBody.call {
        noteId: res
        body: body
        createTransaction: false
      }, (err, bodyRes) ->
        setTimeout ->
          Template.Notes_import.import data, ii + 1, res
        , 10
    else
      setTimeout ->
        Template.Notes_import.import data, ii + 1, res
      , 10
