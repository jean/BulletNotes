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
import '/imports/ui/lib/emoji.coffee'

CONNECTION_ISSUE_TIMEOUT = 5000
# A store which is local to this file?
showConnectionIssue = new ReactiveVar(false)
Meteor.startup ->
  !((name, path, ctx) ->
    latest = undefined
    prev = if name != 'Keen' and window.Keen then window.Keen else false
    ctx[name] = ctx[name] or ready: (fn) ->
      h = document.getElementsByTagName('head')[0]
      s = document.createElement('script')
      w = window
      loaded = undefined
      s.onload = s.onerror =
      s.onreadystatechange = ->
        if s.readyState and !/^c|loade/.test(s.readyState) or loaded
          return
        s.onload = s.onreadystatechange = null
        loaded = 1
        latest = w.Keen
        if prev
          w.Keen = prev
        else
          try
            delete w.Keen
          catch e
            w.Keen = undefined
        ctx[name] = latest
        ctx[name].ready fn
        return

      s.async = 1
      s.src = path
      h.parentNode.insertBefore s, h
      return
    return
  )('KeenAsync', 'https://d26b395fwzu5fz.cloudfront.net/keen-tracking-1.1.3.min.js', this)
  KeenAsync.ready ->
    # Configure a client instance
    Template.App_body.keenClient = new KeenAsync(
      projectId: Meteor.settings.public.keenProjectId
      writeKey: Meteor.settings.public.keenWriteKey
    )
    # Record an event
    Template.App_body.keenClient.recordEvent 'pageviews', title: document.title
    return


  NProgress.start()
  # Only show the connection error box if it has been 5 seconds since
  # the app started
  $(document).on 'keyup', (e) ->
    editingNote = $(document.activeElement).hasClass('title')
    menuVisible = $('#container').hasClass('menu-open')
    switch e.keyCode
      # m - mute
      when 77
        Template.App_body.toggleMute()
      # f - find / search
      when 70
        if Template.App_body.shouldNav()
          $('.searchIcon').addClass('is-focused')
          $('.search').focus()
      # ` Back Tick - toggle menu
      when 192
        if Template.App_body.shouldNav()
          if Meteor.user() && Meteor.user().menuPin
            Meteor.call('users.setMenuPin', {menuPin:false})
            Template.App_body.playSound 'menuClose'
            Template.App_body.showSnackbar
              message: "Menu unpinned"
          else
            Meteor.call('users.setMenuPin', {menuPin:true})
            Template.App_body.playSound 'menuOpen'
            Template.App_body.showSnackbar
              message: "Menu pinned"
      # , comma - load settings
      when 188
        if Template.App_body.shouldNav()
          Template.App_body.playSound 'navigate'
          FlowRouter.go('/settings')
      # 0
      # Home
      when 48, 36
        if Template.App_body.shouldNav()
          Template.App_body.playSound 'navigate'
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

Template.App_body.onRendered ->
  $.urlParam = (name) ->
    results = new RegExp('[?&]' + name + '=([^&#]*)').exec(window.location.href)
    if results
      results[1] or 0

  Session.set 'referral', $.urlParam('ref')

  $(window).keydown (event) ->
    # If we aren't editing anything
    if $(':focus').length < 1

      # Up or down
      if event.keyCode == 40 || event.keyCode == 38
        event.preventDefault()
        Template.note.focus $('.title').first()[0]

      # Cmd + Z Undo
      if event.keyCode == 90 && (event.metaKey || event.ctrlKey)
        event.preventDefault()
        tx.undo()

      # Cmd + Y Redo
      else if event.keyCode == 89 && (event.metaKey || event.ctrlKey)
        event.preventDefault()
        tx.redo()

Template.App_body.onCreated ->
  NoteSubs = new SubsManager
  self = this
  self.ready = new ReactiveVar
  self.autorun ->
    Meteor.subscribe('users.prefs')
    handle = NoteSubs.subscribe('notes.all')
    Meteor.subscribe 'notes.count.total'
    Meteor.subscribe 'notes.count.user'
    Session.set 'ready', handle.ready()
    return
  setTimeout (->
    $('.betaWarning,.devWarning').fadeOut()
    return
  ), 5000

Template.App_body.getTotalNotesAllowed = ->
  if !Meteor.user()
    return 0
  referrals = Meteor.user().referralCount || 0
  Meteor.settings.public.noteLimit + (Meteor.settings.public.referralNoteBonus * referrals)

Template.App_body.loadFavorite = (number) ->
  if Template.App_body.shouldNav() && $('.favoriteNote').get(number-1)
    Template.App_body.playSound 'navigate'
    $('input').val('')
    NProgress.start()
    FlowRouter.go $($('.favoriteNote').get(number-1)).attr 'href'

Template.App_body.shouldNav = () ->
  editingNote = $(document.activeElement).hasClass('title')
  editingFocusedNote = $(document.activeElement).hasClass('title-wrapper')
  editingBody = $(document.activeElement).hasClass('body')
  focused = $('input:focus').length
  return !editingNote && !editingFocusedNote && !editingBody && !focused

Template.App_body.helpers
  siteName: ->
    'BulletNotes.io'

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

    Template.notes.formatText note.title

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

  theme: ->
    if Meteor.user() && Meteor.user().theme
      "url('/img/bgs/"+Meteor.user().theme.toLowerCase()+".jpg')"

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

  viewModeIcon: ->
    if Session.get('viewMode') == "calendar"
      "date_range"
    else if Session.get('viewMode') == "kanban"
      "view_column"
    else
      "fiber_manual_record"

  modeBackgroundLeft: ->
    if Session.get('viewMode') == "calendar"
      40
    else if Session.get('viewMode') == "kanban"
      80
    else
      0

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
    if event.keyCode == 27
      $(event.currentTarget).blur()
    true

  'click #scrollToTop': () ->
    Template.App_body.playSound 'navigate'
    $(".mdl-layout__content").animate({ scrollTop: 0 }, 200)

  'blur .title-wrapper': (event, instance) ->
    event.stopPropagation()
    title = Template.note.stripTags(event.target.innerHTML)
    if title != @title
      Meteor.call 'notes.updateTitle', {
        noteId: FlowRouter.getParam('noteId')
        title: title
        # FlowRouter.getParam 'shareKey',
      }, (err, res) ->
        $(event.target).html Template.notes.formatText title

  'keydown .title-wrapper': (event, instance) ->
    if event.keyCode == 13
      event.preventDefault()
      $(event.currentTarget.blur())

  'click #calendarMode': ->
    Session.set('viewMode','calendar')

  'click #notesMode': ->
    Session.set('viewMode','note')

  'click #kanbanMode': ->
    Session.set('viewMode','kanban')


Template.App_body.playSound = (sound) ->
  if Meteor.user() && !Meteor.user().muted
    audio = new Audio('/snd/'+sound+'.wav')
    audio.volume = .5
    audio.play()

Template.App_body.toggleMute = () ->
  if Template.App_body.shouldNav()
    if Meteor.user().muted
      Meteor.call 'users.setMuted', {muted:false}, (err, res) ->
        Template.App_body.showSnackbar
          message: "Unmuted"
    else
      Meteor.call 'users.setMuted', {muted:true}, (err, res) ->
        Template.App_body.showSnackbar
          message: "Muted"

Template.App_body.showSnackbar = (data) ->
  Template.App_body.playSound 'snackbar'
  document.querySelector('#snackbar').MaterialSnackbar.showSnackbar(data)

UI.registerHelper 'getCount', (name) ->
  if name
    return Counter.get(name)

UI.registerHelper 'getSetting', (name) ->
  if name
    return Meteor.settings.public[name]

UI.registerHelper 'getTimeFromNow', (time) ->
  if time
    moment(time).fromNow()

Template.App_body.recordEvent = (event, data) ->
  if Template.App_body.keenClient
    Template.App_body.keenClient.recordEvent event, data
