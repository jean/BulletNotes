{ Template } = require 'meteor/templating'
{ Notes } = require '../../../api/notes/notes.coffee'
require './exporter.jade'

Template.exporter.events exportContent: ->
  Meteor.call 'notes.export'
Template.exporter.events 'click input.submit': (event) ->
  event.preventDefault()
  $('<i class="fa fa-spinner fa-spin" style="float: left"></i>')
    .insertAfter(event.target)
  $(event.target).remove()
  Meteor.call 'notes.export', (err, res) ->
    $('.exportContent').val res
    $('.fa-spinner').remove()
