require './footer.jade'

Template.footer.onCreated ->
  Meteor.call 'version', (err, version) ->
    $('#version').html version

Template.footer.helpers
  year: ->
    moment().format("YYYY")
