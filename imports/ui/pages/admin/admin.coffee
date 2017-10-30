{ Template } = require 'meteor/templating'

require './admin.jade'

Template.App_admin.onCreated ->
  if !Meteor.user() || !Meteor.user().isAdmin
    FlowRouter.go '/'

Template.App_admin.onRendered ->
  NProgress.done()
  Meteor.subscribe('users.count')

Template.App_admin.helpers
  userCount: ->
    Counter.get('total')