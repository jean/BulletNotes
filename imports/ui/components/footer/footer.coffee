require './footer.jade'

Template.footer.onCreated ->
  Meteor.call 'version', (err, version) ->
    $('#version').html 'v'+version

Template.footer.helpers
  year: ->
    moment().format("YYYY")

  totalNotes: ->
    Counter.get('notes.count.total').toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")
