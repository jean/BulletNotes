{ FlowRouter } = require 'meteor/kadira:flow-router'
{ BlazeLayout } = require 'meteor/kadira:blaze-layout'

require '../../ui/layouts/body/body.coffee'
require '../../ui/pages/home/home.coffee'
require '../../ui/pages/view-note/view-note.coffee'
require '../../ui/pages/search/search.coffee'
require '../../ui/pages/calendar/calendar.coffee'

require '../../ui/pages/not-found/not-found.coffee'

FlowRouter.route '/',
  name: 'App.home'
  action: ->
    BlazeLayout.render 'App_body', main: 'App_home'

FlowRouter.route '/note/:noteId',
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

FlowRouter.notFound =
  action: ->
    BlazeLayout.render('App_body', { main: 'App_notFound' });
