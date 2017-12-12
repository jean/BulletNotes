{ FlowRouter } = require 'meteor/kadira:flow-router'
{ BlazeLayout } = require 'meteor/kadira:blaze-layout'

import { Notes } from '/imports/api/notes/notes.coffee'

require '/imports/ui/layouts/app-body.coffee'

require '/imports/ui/layouts/app-botPage.coffee'

require '/imports/ui/pages/404/app-not-found.coffee'
require '/imports/ui/pages/account/account.coffee'
require '/imports/ui/pages/admin/admin.coffee'
require '/imports/ui/pages/import/import.coffee'
require '/imports/ui/pages/notes/notes-show-page.coffee'
require '/imports/ui/pages/root-redirector.js'
require '/imports/ui/pages/pricing/pricing.coffee'
require '/imports/ui/pages/intro/intro.coffee'
require '/imports/ui/pages/privacy/privacy.coffee'
require '/imports/ui/pages/settings/settings.coffee'
require '/imports/ui/pages/terms/terms.coffee'
require '/imports/ui/pages/zoom/zoom.coffee'

# Import to override accounts templates
require '/imports/ui/accounts/accounts-templates.coffee'

FlowRouter.route '/',
  name: 'App.home'
  action: ->
    NProgress.start()
    Session.set 'searchTerm', null
    BlazeLayout.render 'App_body', main: 'Notes_show_page'

FlowRouter.route '/note/:noteId',
  name: 'Notes.show'
  action: ->
    NProgress.start()

    # Check if the note is a Kanban or Calendar note
    # If so, set the view mode to that
    Meteor.subscribe 'notes.view',
      FlowRouter.getParam 'noteId'
      FlowRouter.getParam 'shareKey'
    note = Notes.findOne FlowRouter.getParam 'noteId',
      fields:
        title: yes

    if note
      if note.title.includes "#kanban"
        Session.set 'viewMode', "kanban"
      else if note.title.includes "#calendar"
        Session.set 'viewMode', "calendar"
      else if note.title.includes "#notes"
        Session.set 'viewMode', "notes"

    BlazeLayout.render 'App_body', main: 'Notes_show_page'

FlowRouter.route '/note/:noteId/:shareKey',
  name: 'Notes.showShared'
  action: ->
    NProgress.start()
    BlazeLayout.render 'App_body', main: 'Notes_show_page'

FlowRouter.route '/search/:searchTerm',
  name: 'Notes.search'
  action: ->
    NProgress.start()
    BlazeLayout.render 'App_body', main: 'Notes_show_page'

FlowRouter.route '/calendar',
  name: 'Notes.calendar'
  action: ->
    NProgress.start()
    Session.set('viewMode',"calendar")
    BlazeLayout.render 'App_body', main: 'Notes_show_page'

FlowRouter.route '/calendar/:noteId',
  name: 'Notes.calendar'
  action: ->
    NProgress.start()
    Session.set('viewMode',"calendar")
    BlazeLayout.render 'App_body', main: 'Notes_show_page'

FlowRouter.route '/kanban',
  name: 'Notes.kanban'
  action: ->
    NProgress.start()
    Session.set('viewMode',"kanban")
    BlazeLayout.render 'App_body', main: 'Notes_show_page'

FlowRouter.route '/kanban/:noteId',
  name: 'Notes.kanban'
  action: ->
    NProgress.start()
    Session.set('viewMode',"kanban")
    BlazeLayout.render 'App_body', main: 'Notes_show_page'

FlowRouter.route '/import',
  name: 'Notes.import'
  action: ->
    NProgress.start()
    BlazeLayout.render 'App_body', main: 'Notes_import'

FlowRouter.route '/account',
  name: 'App.account'
  action: ->
    NProgress.start()
    BlazeLayout.render 'App_body', main: 'App_account'

FlowRouter.route '/settings',
  name: 'App.settings'
  action: ->
    NProgress.start()
    BlazeLayout.render 'App_body', main: 'App_settings'

FlowRouter.route '/zoom',
  name: 'App.zoom'
  action: ->
    NProgress.start()
    BlazeLayout.render 'App_body', main: 'App_zoom'

FlowRouter.route '/admin',
  name: 'App.admin'
  action: ->
    NProgress.start()

    BlazeLayout.render 'App_body', main: 'App_admin'

FlowRouter.route '/telegramAuth/:telegramId',
  name: 'App.telegramAuth'
  action: ->
    Meteor.call 'users.setTelegramId', {
      id: FlowRouter.getParam('telegramId')
    }, (error, result) ->
      if !error
        Template.App_body.showSnackbar
          message: "Telegram account linked successfully!"
      else
        Template.App_body.showSnackbar
          message: "Error occured while linking Telegram account."
    FlowRouter.redirect '/'

FlowRouter.route '/dropboxAuth',
  name: 'App.dropboxAuth'
  action: ->
    parseQueryString = (str) ->
      ret = Object.create(null)
      if typeof str != 'string'
        return ret
      str = str.trim().replace(/^(\?|#|&)/, '')
      if !str
        return ret
      str.split('&').forEach (param) ->
        parts = param.replace(/\+/g, ' ').split('=')
        # Firefox (pre 40) decodes `%3D` to `=`
        # https://github.com/sindresorhus/query-string/pull/37
        key = parts.shift()
        val = if parts.length > 0 then parts.join('=') else undefined
        key = decodeURIComponent(key)
        # missing `=` should be `null`:
        # http://w3.org/TR/2012/WD-url-20120524/#collect-url-parameters
        val = if val == undefined then null else decodeURIComponent(val)
        if ret[key] == undefined
          ret[key] = val
        else if Array.isArray(ret[key])
          ret[key].push val
        else
          ret[key] = [
            ret[key]
            val
          ]
        return
      ret

    Meteor.call 'users.setDropboxOauth', {
      access_token: parseQueryString(window.location.hash)['access_token']
    }, (error, result) ->
      if !error
        Template.App_body.showSnackbar
          message: "Dropbox account linked successfully!"
      else
        Template.App_body.showSnackbar
          message: "Error occured while linking Dropbox account."
    FlowRouter.redirect '/'

FlowRouter.route '/bot',
  name: 'App.botPage'
  action: ->
    NProgress.start()
    BlazeLayout.render 'App_botPage'

FlowRouter.route '/pricing',
  name: 'App.pricing'
  action: ->
    NProgress.start()
    BlazeLayout.render 'App_body', main: 'App_pricing'

FlowRouter.route '/terms',
  name: 'App.terms'
  action: ->
    NProgress.start()
    BlazeLayout.render 'App_body', main: 'App_terms'

FlowRouter.route '/privacy',
  name: 'App.privacy'
  action: ->
    NProgress.start()
    BlazeLayout.render 'App_body', main: 'App_privacy'

FlowRouter.route '/intro',
  name: 'App.intro'
  action: ->
    NProgress.start()
    BlazeLayout.render 'App_body', main: 'App_intro'

FlowRouter.notFound =
  action: ->
    BlazeLayout.render('App_body', { main: 'App_notFound' })
