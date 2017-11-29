require './privacy.jade'

Template.App_privacy.onRendered ->
  NProgress.done()
  $(".mdl-layout__content").animate({ scrollTop: 0 }, 200)
