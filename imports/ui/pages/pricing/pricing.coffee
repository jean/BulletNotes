import './pricing.jade'

Template.App_pricing.onRendered ->
  NProgress.done()

Template.App_pricing.helpers
    noteLimit: ->
        Meteor.settings.public.noteLimit