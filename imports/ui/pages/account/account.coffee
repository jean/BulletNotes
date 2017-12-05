{ Template } = require 'meteor/templating'

require './account.jade'

Template.App_account.updateSubscription = (subscription) ->
  if subscription
    $('#proPlan').show()
    $('#freePlan').hide()
    $('#trialButton').fadeOut()
    if subscription.canceled_at
      $('#AccountStatus').html( 'Your subscription will end ' + Template.App_account.fromNow(subscription.current_period_end) )
      $('#stopSubscription').fadeOut()
    else
      if subscription.status == "trial"
        $('#AccountStatus').html( 'Your trial will end and you will be billed $' + Meteor.settings.public.proPrice + ' ' + Template.App_account.fromNow(subscription.trial_end) )
      else
        $('#AccountStatus').html( 'You will be billed $' + Meteor.settings.public.proPrice + ' ' + Template.App_account.fromNow(subscription.current_period_end) )
      $('#stopSubscription').fadeIn()
  else
    $('#proPlan').hide()
    $('#freePlan').show()
    $('#trialButton').fadeIn()
    $('#stopSubscription').fadeOut()

Template.App_account.fromNow = (time) ->
  if time
    'on ' + moment(parseInt(time+'000',10)).format('YYYY-MM-DD')

Template.App_account.onRendered ->
  NProgress.done()
  Meteor.call 'users.getSubscription', (err, res) ->
    Template.App_account.updateSubscription res

Template.App_account.helpers
  extraNotesEarned: ->
    (Meteor.user().referralCount || 0) * Meteor.settings.public.referralNoteBonus
  
  url: ->
    Meteor.absoluteUrl()
  
  referralCount: ->
  	Meteor.user().referralCount || 0

  referralNoteBonus: ->
    Meteor.settings.public.referralNoteBonus

  proPrice: ->
    Meteor.settings.public.proPrice

Template.App_account.events
  'click #trialButton': (event, instance) ->
    $('#trialButton').fadeOut()
    $('#payment-form').fadeIn()
    stripe = Stripe(Meteor.settings.public.stripePublicKey)
    elements = stripe.elements()
    card = elements.create('card')
    card.mount '#card-element'
    form = document.getElementById('payment-form')
    form.addEventListener 'submit', (event) ->
      event.preventDefault()
      $(event.target).fadeOut()
      stripe.createToken(card).then (result) ->
        if result.error
          # Inform the user if there was an error
          errorElement = document.getElementById('card-errors')
          errorElement.textContent = result.error.message
        else
          Meteor.call 'users.startTrial',
            stripeToken: result.token.id
          , (err, res) ->
            Template.App_account.updateSubscription res

  'click #stopSubscription': (event, instance) ->
    $('#stopSubscription').fadeOut()
    Meteor.call 'users.stopSubscription',
      (err, res) ->
        Template.App_account.updateSubscription res