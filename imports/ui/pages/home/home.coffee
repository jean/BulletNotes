require './home.jade'
require '../../components/notes/notes.coffee'

Template.App_home.onCreated ->
  Session.set 'searchTerm', ''
  return