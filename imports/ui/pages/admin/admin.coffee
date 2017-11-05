{ Template } = require 'meteor/templating'

require './admin.jade'

Template.App_admin.onCreated ->
  if !Meteor.user() || !Meteor.user().isAdmin
    FlowRouter.go '/'

Template.App_admin.onRendered ->
  NProgress.done()
  Meteor.subscribe('users.count.total')
  Meteor.subscribe('notes.count.recent')