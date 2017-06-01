{ Template } = require 'meteor/templating'

require './admin.jade'

Template.App_admin.onRendered ->
  NProgress.done()
