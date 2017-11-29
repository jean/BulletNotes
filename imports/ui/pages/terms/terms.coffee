require './terms.jade'

Template.App_terms.onRendered ->
  NProgress.done()
  $(".mdl-layout__content").animate({ scrollTop: 0 }, 200)
