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
  # Append rollbar tracking
  $('<script>')
    .attr('type', 'text/javascript')
    .text('var _rollbarConfig = {
    accessToken: "9787fb0d1c82430f8d3139a4cf3ae742",
    captureUncaught: true,
    captureUnhandledRejections: true,
    payload: {
        environment: "'+Meteor.settings.public.environment+'"
    }
    };!function(r){function e(n){if(o[n])return o[n].exports;var t=o[n]={exports:{},id:n,loaded:!1};return r[n].call(t.exports,t,t.exports,e),t.loaded=!0,t.exports}var o={};return e.m=r,e.c=o,e.p="",e(0)}([function(r,e,o){"use strict";var n=o(1).Rollbar,t=o(2);_rollbarConfig.rollbarJsUrl=_rollbarConfig.rollbarJsUrl||"https://cdnjs.cloudflare.com/ajax/libs/rollbar.js/1.9.3/rollbar.min.js";var a=n.init(window,_rollbarConfig),i=t(a,_rollbarConfig);a.loadFull(window,document,!_rollbarConfig.async,_rollbarConfig,i)},function(r,e){"use strict";function o(r){return function(){try{return r.apply(this,arguments)}catch(r){try{console.error("[Rollbar]: Internal error",r)}catch(r){}}}}function n(r,e,o){window._rollbarWrappedError&&(o[4]||(o[4]=window._rollbarWrappedError),o[5]||(o[5]=window._rollbarWrappedError._rollbarContext),window._rollbarWrappedError=null),r.uncaughtError.apply(r,o),e&&e.apply(window,o)}function t(r){var e=function(){var e=Array.prototype.slice.call(arguments,0);n(r,r._rollbarOldOnError,e)};return e.belongsToShim=!0,e}function a(r){this.shimId=++c,this.notifier=null,this.parentShim=r,this._rollbarOldOnError=null}function i(r){var e=a;return o(function(){if(this.notifier)return this.notifier[r].apply(this.notifier,arguments);var o=this,n="scope"===r;n&&(o=new e(this));var t=Array.prototype.slice.call(arguments,0),a={shim:o,method:r,args:t,ts:new Date};return window._rollbarShimQueue.push(a),n?o:void 0})}function l(r,e){if(e.hasOwnProperty&&e.hasOwnProperty("addEventListener")){var o=e.addEventListener;e.addEventListener=function(e,n,t){o.call(this,e,r.wrap(n),t)};var n=e.removeEventListener;e.removeEventListener=function(r,e,o){n.call(this,r,e&&e._wrapped?e._wrapped:e,o)}}}var c=0;a.init=function(r,e){var n=e.globalAlias||"Rollbar";if("object"==typeof r[n])return r[n];r._rollbarShimQueue=[],r._rollbarWrappedError=null,e=e||{};var i=new a;return o(function(){if(i.configure(e),e.captureUncaught){i._rollbarOldOnError=r.onerror,r.onerror=t(i);var o,a,c="EventTarget,Window,Node,ApplicationCache,AudioTrackList,ChannelMergerNode,CryptoOperation,EventSource,FileReader,HTMLUnknownElement,IDBDatabase,IDBRequest,IDBTransaction,KeyOperation,MediaController,MessagePort,ModalWindow,Notification,SVGElementInstance,Screen,TextTrack,TextTrackCue,TextTrackList,WebSocket,WebSocketWorker,Worker,XMLHttpRequest,XMLHttpRequestEventTarget,XMLHttpRequestUpload".split(",");for(o=0;o<c.length;++o)a=c[o],r[a]&&r[a].prototype&&l(i,r[a].prototype)}return e.captureUnhandledRejections&&(i._unhandledRejectionHandler=function(r){var e=r.reason,o=r.promise,n=r.detail;!e&&n&&(e=n.reason,o=n.promise),i.unhandledRejection(e,o)},r.addEventListener("unhandledrejection",i._unhandledRejectionHandler)),r[n]=i,i})()},a.prototype.loadFull=function(r,e,n,t,a){var i=function(){var e;if(void 0===r._rollbarPayloadQueue){var o,n,t,i;for(e=new Error("rollbar.js did not load");o=r._rollbarShimQueue.shift();)for(t=o.args,i=0;i<t.length;++i)if(n=t[i],"function"==typeof n){n(e);break}}"function"==typeof a&&a(e)},l=!1,c=e.createElement("script"),p=e.getElementsByTagName("script")[0],s=p.parentNode;c.crossOrigin="",c.src=t.rollbarJsUrl,c.async=!n,c.onload=c.onreadystatechange=o(function(){if(!(l||this.readyState&&"loaded"!==this.readyState&&"complete"!==this.readyState)){c.onload=c.onreadystatechange=null;try{s.removeChild(c)}catch(r){}l=!0,i()}}),s.insertBefore(c,p)},a.prototype.wrap=function(r,e){try{var o;if(o="function"==typeof e?e:function(){return e||{}},"function"!=typeof r)return r;if(r._isWrap)return r;if(!r._wrapped){r._wrapped=function(){try{return r.apply(this,arguments)}catch(e){throw"string"==typeof e&&(e=new String(e)),e._rollbarContext=o()||{},e._rollbarContext._wrappedSource=r.toString(),window._rollbarWrappedError=e,e}},r._wrapped._isWrap=!0;for(var n in r)r.hasOwnProperty(n)&&(r._wrapped[n]=r[n])}return r._wrapped}catch(e){return r}};for(var p="log,debug,info,warn,warning,error,critical,global,configure,scope,uncaughtError,unhandledRejection".split(","),s=0;s<p.length;++s)a.prototype[p[s]]=i(p[s]);r.exports={Rollbar:a,_rollbarWindowOnError:n}},function(r,e){"use strict";r.exports=function(r,e){return function(o){if(!o&&!window._rollbarInitialized){var n=window.RollbarNotifier,t=e||{},a=t.globalAlias||"Rollbar",i=window.Rollbar.init(t,r);i._processShimQueue(window._rollbarShimQueue||[]),window[a]=i,window._rollbarInitialized=!0,n.processPayloads()}}}}]);')
    .appendTo('head')

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
  editingNote = $(document.activeElement).hasClass('title')
  menuVisible = $('#container').hasClass('menu-open')
  if !editingNote
    FlowRouter.go $($('.parentNote').get(number-1)).attr 'href'
    if menuVisible
      $('.nav-item').trigger 'click'

Template.App_body.helpers
  menuOpen: ->
    instance = Template.instance()
    instance.state.get('menuOpen') and 'menu-open'
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
    instance.state.get 'recentMenuOpen'
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
      return
    'swiperight .cordova': (event, instance) ->
      instance.state.set 'menuOpen', true
      return
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
    Session.set 'searchTerm', $(event.target).val()

  'click .js-menu': (event, instance) ->
    instance.state.set 'menuOpen', !instance.state.get('menuOpen')

  'click .content-overlay': (event, instance) ->
    instance.state.set 'menuOpen', false
    event.preventDefault()

  'click .userMenu': (event, instance) ->
    event.stopImmediatePropagation()
    instance.state.set 'userMenuOpen', !instance.state.get('userMenuOpen')

  'click .recentMenu': (event, instance) ->
    event.stopImmediatePropagation()
    instance.state.set 'recentMenuOpen', !instance.state.get('recentMenuOpen')

  'click #menu a': (event, instance) ->
    instance.state.set 'menuOpen', false
    instance.state.set 'userMenuOpen', false

  'click .js-logout': ->
    Meteor.logout()
    # if we are on a private note, we'll need to go to a public one
    if ActiveRoute.name('Notes.show')
      # TODO -- test this code path
      note = Notes.findOne(FlowRouter.getParam('_id'))
      if note.userId
        FlowRouter.go 'Notes.show', Notes.findOne(userId: $exists: false)

  'click .js-toggle-language': (event) ->
    language = $(event.target).html().trim()
    T9n.setLanguage language
    TAPi18n.setLanguage language

