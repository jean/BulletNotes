require './not-found.jade'

Template.App_notFound.onCreated ->
  Session.set 'searchTerm', ''
  return