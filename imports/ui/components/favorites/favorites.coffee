{ Template } = require 'meteor/templating'
{ Notes } = require '../../../api/notes/notes.coffee'
require './favorites.jade'


Template.favorites.helpers
  'favorites': ->
    Meteor.subscribe 'notes.favorites'
    Notes.find {favorite: true}, sort: favoritedAt: -1
