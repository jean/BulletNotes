{ Template } = require 'meteor/templating'
{ ReactiveDict } = require 'meteor/reactive-dict'
{ Notes } = require '/imports/api/notes/notes.coffee'

require './menu.jade'

Template.menu.onCreated ->
  @state = new ReactiveDict
  @state.setDefault
    menuOpen: false
    userMenuOpen: false

Template.menu.helpers
  displayName: ->
    displayName = ''
    if Meteor.user().emails
      email = Meteor.user().emails[0].address
      displayName = email.substring(0, email.indexOf('@'))
    else
      displayName = Meteor.user().profile.name
    displayName

  userMenuOpen: ->
    instance = Template.instance()
    instance.state.get 'userMenuOpen'

  recentMenuOpen: ->
    instance = Template.instance()
    Session.get 'recentMenuOpen'

  notes: ->
    Notes.find { favorite: true }, sort: favoritedAt: -1

  activeNoteClass: (note) ->
    active = ActiveRoute.name('Notes.show') and FlowRouter.getParam('_id') == note._id
    active and 'active'

Template.menu.events
  'click .js-menu': (event, instance) ->
    Session.set 'menuOpen', !Session.get('menuOpen')

  'click .userMenu': (event, instance) ->
    event.stopImmediatePropagation()
    instance.state.set 'userMenuOpen', !instance.state.get('userMenuOpen')

  'click .recentMenu': (event, instance) ->
    event.stopImmediatePropagation()
    Session.set 'recentMenuOpen', !Session.get('recentMenuOpen')

  'click .recentLink': (event, instance) ->
    Session.set 'recentMenuOpen', false

  'click .js-logout': ->
    Meteor.logout()
    FlowRouter.go '/'

  'click .homeLink': ->
    $('#searchForm input').val('')

  'click .js-toggle-language': (event) ->
    language = $(event.target).html().trim()
    T9n.setLanguage language
    TAPi18n.setLanguage language

Template.registerHelper 'increment', (count) ->
  return count + 1
