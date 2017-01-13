{ Template } = require 'meteor/templating'
{ Notes } = require '../../../api/notes/notes.js'
require './exporter.jade'

Template.exporter.events exportContent: ->
  Meteor.call 'notes.export'
Template.exporter.events 'click input.submit': (event) ->
  event.preventDefault()
  Meteor.call 'notes.export', (err, res) ->
    $('.exportContent').val res
    return
  return
