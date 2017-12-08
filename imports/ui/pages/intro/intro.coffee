import './intro.jade'

Template.App_intro.onRendered ->
	if Meteor.user()
      FlowRouter.go '/'
  NProgress.done()
  $(".mdl-layout__content").animate({ scrollTop: 0 }, 200)
  Session.set 'introLoaded', true