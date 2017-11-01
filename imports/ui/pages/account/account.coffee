{ Template } = require 'meteor/templating'

require './account.jade'

Template.App_account.onRendered ->
  NProgress.done()

Template.App_account.helpers
  extraNotesEarned: ->
    Meteor.user().referralCount * Meteor.settings.public.referralNoteBonus
  
  url: ->
    Meteor.absoluteUrl()
  
  referralNoteBonus: ->
    Meteor.settings.public.referralNoteBonus