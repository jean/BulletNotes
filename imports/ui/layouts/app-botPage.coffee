import './app-botPage.jade'

import '/imports/ui/components/botWidget/botWidget.coffee'

Template.App_botPage.onRendered ->
	NProgress.done()
	Session.set 'showBotWidget', false
	$('input').focus()