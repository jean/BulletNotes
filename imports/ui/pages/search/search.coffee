require './search.jade'

Template.App_search.helpers searchTerm: ->
  FlowRouter.getParam 'searchTerm'
