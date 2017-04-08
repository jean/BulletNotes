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

import '/imports/ui/components/loading/loading.coffee'
import '/imports/ui/components/menu/menu.coffee'
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
    Meteor.subscribe('users.prefs')
    handle = NoteSubs.subscribe('notes.all')
    Session.set 'ready', handle.ready()
    return
  setTimeout (->
    $('.betaWarning,.devWarning').fadeOut()
    return
  ), 5000

Template.App_body.loadFavorite = (number) ->
  editingNote = $(document.activeElement).hasClass('title')
  editingFocusedNote = $(document.activeElement).hasClass('title-wrapper')
  editingBody = $(document.activeElement).hasClass('body')
  if !editingNote && !editingFocusedNote && !editingBody && ( $('input:focus').length < 1 )
    $('input').val('')
    NProgress.start()
    FlowRouter.go $($('.favoriteNote').get(number-1)).attr 'href'
    menuVisible = $('#container').hasClass('menu-open')
    if menuVisible
      $('.nav-item').trigger 'click'

Template.App_body.helpers
  wrapClasses: ->
    classname = ''
    if Meteor.isCordova
      classname += 'cordova'
    if Meteor.settings.public.dev
      classname += ' dev'
    classname

  dev: ->
    Meteor.settings.public.dev

  connected: ->
    if showConnectionIssue.get()
      return Meteor.status().connected
    true

  focusedNote: ->
    Notes.findOne FlowRouter.getParam 'noteId',
      fields:
        _id: yes
        body: yes
        title: yes
        favorite: yes
        children: yes

  focusedNoteTitle: ->
    note = Notes.findOne FlowRouter.getParam('noteId'),
      fields:
        _id: yes
        title: yes
    emojione.shortnameToUnicode note.title

  focusedNoteFiles: () ->
    Meteor.subscribe 'files.note', FlowRouter.getParam 'noteId'
    Files.find { noteId: FlowRouter.getParam 'noteId' }

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
    Session.get 'ready'

  menuPin: ->
    if Meteor.user() && Meteor.user().menuPin
      'mdl-layout--fixed-drawer'

  noteArgs: () ->
    instance = Template.instance()
    # By finding the note with only the `_id` field set,
    # we don't create a dependency on the
    # `note.incompleteCount`, and avoid re-rendering the todos when it changes
    note = Notes.findOne FlowRouter.getParam('noteId'),
      fields:
        _id: yes

    ret =
      todosReady: instance.subscriptionsReady()
      # We pass `note` (which contains the full note, with all fields, as a function
      # because we want to control reactivity. When you check a todo item, the
      # `note.incompleteCount` changes. If we didn't do this the entire note would
      # re-render whenever you checked an item. By isolating the reactiviy on the note
      # to the area that cares about it, we stop it from happening.
      note: ->
        Notes.findOne FlowRouter.getParam('noteId')


Template.App_body.events
  'keyup .search': (event, instance) ->
    # Throttle so we don't search for single letters
    clearTimeout(Template.App_body.timer)
    Template.App_body.timer = setTimeout ->
      if $(event.target).val()
        FlowRouter.go '/search/' + $(event.target).val()
      else
        FlowRouter.go '/'
    , 500

Template.App_body.playSound = (sound) ->
  if !Meteor.user().muted
    audio = new Audio('/snd/'+sound+'.wav')
    audio.volume = .5
    audio.play()
