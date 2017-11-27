import './pricing.jade'

Template.App_pricing.onRendered ->
  NProgress.done()
  $(".mdl-layout__content").animate({ scrollTop: 0 }, 200)

Template.App_pricing.helpers
    noteLimit: ->
        Meteor.settings.public.noteLimit