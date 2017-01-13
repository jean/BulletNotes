{ FlowRouter } = require 'meteor/kadira:flow-router'
{ BlazeLayout } = require 'meteor/kadira:blaze-layout'

require '../../ui/layouts/body/body.coffee'
require '../../ui/pages/home/home.js'
require '../../ui/pages/view-note/view-note.js'
require '../../ui/pages/search/search.js'
require '../../ui/pages/not-found/not-found.js'

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


FlowRouter.notFound =
  action: ->
    BlazeLayout.render('App_body', { main: 'App_notFound' });
