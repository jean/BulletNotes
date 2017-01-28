{ FlowRouter } = require 'meteor/kadira:flow-router'
{ BlazeLayout } = require 'meteor/kadira:blaze-layout'

# require '../../ui/pages/search/search.coffee'
# require '../../ui/pages/calendar/calendar.coffee'

# Import to load these templates
require '../../ui/layouts/app-body.js'
require '../../ui/pages/root-redirector.js'
require '../../ui/pages/notes/show/show.coffee'
require '../../ui/pages/app-not-found.js'

# Import to override accounts templates
require '../../ui/accounts/accounts-templates.js'

FlowRouter.route '/note/:noteId',
  name: 'App.viewNote'
  action: ->
    console.log "Got it"
    BlazeLayout.render('App_body', { main: 'App_notFound' })
    BlazeLayout.render 'App_body', main: 'Notes_show'

FlowRouter.route '/note/:noteId/:shareKey',
  name: 'App.viewNote'
  action: ->
    BlazeLayout.render 'App_body', main: 'App_viewNote'

FlowRouter.route '/search/:searchTerm',
  name: 'App.search'
  action: ->
    BlazeLayout.render 'App_body', main: 'App_search'

FlowRouter.route '/calendar',
  name: 'App.calendar'
  action: ->
    BlazeLayout.render 'App_body', main: 'App_calendar'

FlowRouter.route '/calendar/:noteId',
  name: 'App.calendar'
  action: ->
    BlazeLayout.render 'App_body', main: 'App_calendar'

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

    Meteor.call 'users.setDropboxOauth',
      parseQueryString(window.location.hash)['access_token']
    FlowRouter.redirect '/'

FlowRouter.notFound =
  action: ->
    BlazeLayout.render('App_body', { main: 'App_notFound' })
