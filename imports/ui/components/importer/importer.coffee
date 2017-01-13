{ Template } = require 'meteor/templating'
{ Notes } = require '../../../api/notes/notes.coffee'
require './importer.jade'

Template.importer.events 'click input.submit': (event) ->
  event.preventDefault()
  data = {}
  data.importLines = $(event.currentTarget).parent().parent().find('textarea').get(0).value.split('\n')
  $(event.currentTarget).parent().parent().find('textarea').get(0).value = ''
  data.prevLevel = 0
  data.prevParents = []
  data.levelRanks = []
  Template.importer.import data
  return

Template.importer.import = (data, row = 0, lastNote = null) ->
  ii = row
  while ii < data.importLines.length
    line = data.importLines[ii]
    if line.trim().substr(0, 1) != '-'
      # Invalid line
      ii++
      continue
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
    # Check if the next line is a body
    nextLine = data.importLines[ii + 1]
    body = null
    if nextLine and nextLine.trim().substr(0, 1) == '"'
      body = nextLine.trim().substr(1)
      body = body.substr(0, body.length)
    Meteor.call 'notes.insert', title, data.levelRanks[level], parent, level, (err, res) ->
      if body
        Meteor.call 'notes.updateBody', res, body
      Template.importer.import data, ii + 1, res
      return
    break
    ii++
  return

