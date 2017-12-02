{ Template } = require 'meteor/templating'

require './account.jade'

Template.App_account.onRendered ->
  NProgress.done()

Template.App_account.helpers
  extraNotesEarned: ->
    (Meteor.user().referralCount || 0) * Meteor.settings.public.referralNoteBonus
  
  url: ->
    Meteor.absoluteUrl()
  
  referralCount: ->
  	Meteor.user().referralCount || 0

  referralNoteBonus: ->
    Meteor.settings.public.referralNoteBonus