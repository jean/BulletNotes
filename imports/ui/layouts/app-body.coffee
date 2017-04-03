import { Meteor } from 'meteor/meteor'
import { ReactiveVar } from 'meteor/reactive-var'
import { ReactiveDict } from 'meteor/reactive-dict'
import { Template } from 'meteor/templating'
import { ActiveRoute } from 'meteor/zimme:active-route'
import { FlowRouter } from 'meteor/kadira:flow-router'
import { TAPi18n } from 'meteor/tap:i18n'
import { T9n } from 'meteor/softwarerero:accounts-t9n'
import { _ } from 'meteor/underscore'
import { $ } from 'meteor/jquery'

import { Notes } from '/imports/api/notes/notes.coffee'
import { insert } from '/imports/api/notes/methods.coffee'

import '../components/loading/loading.coffee'
import './app-body.jade'

CONNECTION_ISSUE_TIMEOUT = 5000
# A store which is local to this file?
showConnectionIssue = new ReactiveVar(false)
Meteor.startup ->
  NProgress.start()
  # Only show the connection error box if it has been 5 seconds since
  # the app started
  $(document).on 'keyup', (e) ->
    editingNote = $(document.activeElement).hasClass('title')
    menuVisible = $('#container').hasClass('menu-open')
    switch e.keyCode
      # f
      when 70
        if e.ctrlKey
          $('.nav-item').trigger 'click'
          $('.search').focus()
      # `
      when 192
        if !editingNote
          $('.nav-item').trigger 'click'
      # 0
      # Home
      when 48, 36
        if !editingNote
          FlowRouter.go('/')
      # 1
      when 49
        Template.App_body.loadFavorite 1
      # 2
      when 50
        Template.App_body.loadFavorite 2
      # 3
      when 51
        Template.App_body.loadFavorite 3
      # 4
      when 52
        Template.App_body.loadFavorite 4
      # 5
      when 53
        Template.App_body.loadFavorite 5
      # 6
      when 54
        Template.App_body.loadFavorite 6
      # 7
      when 55
        Template.App_body.loadFavorite 7
      # 8
      when 56
        Template.App_body.loadFavorite 8
      # 9
      when 57
        Template.App_body.loadFavorite 9

  setTimeout (->
    # FIXME:
    # Launch screen handle created in lib/router.js
    # dataReadyHold.release();
    # Show the connection error box
    showConnectionIssue.set true
    return
  ), CONNECTION_ISSUE_TIMEOUT
  return
Template.App_body.onCreated ->
  NoteSubs = new SubsManager
  self = this
  self.ready = new ReactiveVar
  self.autorun ->
    handle = NoteSubs.subscribe('notes.all')
    self.ready.set handle.ready()
    return
  @state = new ReactiveDict
  @state.setDefault
    menuOpen: false
    userMenuOpen: false
  setTimeout (->
    $('.betaWarning').fadeOut()
    return
  ), 5000
  setTimeout (->
    $('.devWarning').fadeOut()
    return
  ), 10000

Template.App_body.loadFavorite = (number) ->
  $('#searchForm input').val('')
  editingNote = $(document.activeElement).hasClass('title')
  menuVisible = $('#container').hasClass('menu-open')
  if !editingNote
    NProgress.start()
    FlowRouter.go $($('.favoriteNote').get(number-1)).attr 'href'
    if menuVisible
      $('.nav-item').trigger 'click'

Template.App_body.helpers
  menuOpen: ->
    Session.get('menuOpen') and 'menu-open'

  wrapClasses: ->
    classname = ''
    if Meteor.isCordova
      classname += 'cordova'
    if Meteor.settings.public.dev
      classname += ' dev'
    classname

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

  dev: ->
    Meteor.settings.public.dev

  notes: ->
    Notes.find { favorite: true }, sort: favoritedAt: -1

  activeNoteClass: (note) ->
    active = ActiveRoute.name('Notes.show') and FlowRouter.getParam('_id') == note._id
    active and 'active'

  connected: ->
    if showConnectionIssue.get()
      return Meteor.status().connected
    true

  templateGestures:
    'swipeleft .cordova': (event, instance) ->
      instance.state.set 'menuOpen', false

    'swiperight .cordova': (event, instance) ->
      instance.state.set 'menuOpen', true

  languages: ->
    _.keys TAPi18n.getLanguages()

  isActiveLanguage: (language) ->
    TAPi18n.getLanguage() == language

  expandClass: ->
    instance = Template.instance()
    if instance.state.get('menuOpen') then 'expanded' else ''

  ready: ->
    instance = Template.instance()
    instance.ready.get()

Template.App_body.events
  'keyup #searchForm': (event, instance) ->
    if $(event.target).val()
      FlowRouter.go '/search/' + $(event.target).val()
    else
      FlowRouter.go '/'

  'submit #searchForm': (event, instance) ->
    event.preventDefault()

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
