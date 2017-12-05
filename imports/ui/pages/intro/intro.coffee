import './intro.jade'

Template.App_intro.onRendered ->
  NProgress.done()
  $(".mdl-layout__content").animate({ scrollTop: 0 }, 200)