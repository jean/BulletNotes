require './footer.jade'

Template.footer.helpers
  year: ->
    moment().format("YYYY")
