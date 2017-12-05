import { Meteor } from 'meteor/meteor'
import { _ } from 'meteor/underscore'
import { ValidatedMethod } from 'meteor/mdg:validated-method'
import SimpleSchema from 'simpl-schema'
import { DDPRateLimiter } from 'meteor/ddp-rate-limiter'
import { Random } from 'meteor/random'

export referral = new ValidatedMethod
  name: 'users.referral'
  validate: null
  run: ({ referral }) ->
    Meteor.users.update {_id:referral}, {$inc:{referralCount:1}}
    Meteor.users.update {_id:@userId}, {$set:{referredBy:@userId}}

export generateApiKey = new ValidatedMethod
  name: 'users.generateApiKey'
  validate: null
  run: () ->
    Meteor.users.update {_id:@userId}, {$set:{apiKey:Random.hexString( 32 )}}

export startTrial = new ValidatedMethod
  name: 'users.startTrial'
  validate: new SimpleSchema
    stripeToken:
      type: String
      optional: true
  .validator
    clean: yes
    filter: no
  run: ({ stripeToken }) ->
    Stripe = require('stripe')(Meteor.settings.stripeSecretKey)
    userId = @userId
    user = Meteor.user()
    email = user && user.emails && user.emails[0].address
    stripeCustomersCreateSync = Meteor.wrapAsync Stripe.customers.create, Stripe.customers
    customer = stripeCustomersCreateSync { source: stripeToken, email: email, metadata: {userId:user._id} }

    customerId = customer.id

    stripeSubscriptionsCreateSync = Meteor.wrapAsync Stripe.subscriptions.create, Stripe.subscriptions
    subscription = stripeSubscriptionsCreateSync { 
      customer: customerId,
      trial_period_days: 31,
      # End one minute from now, for testing
      # trial_end: moment().unix()+60
      items: [
        {
          plan: "pro",
        },
      ],
    }

    Meteor.users.update {_id:userId}, {$set:{stripeId:customer.id,stripeSubscriptionId:subscription.id,isPro:1}}

    subscription

export getSubscription = new ValidatedMethod
  name: 'users.getSubscription'
  validate: null
  run: ({ }) ->
    if !Meteor.user() || !Meteor.user().stripeSubscriptionId
      return false

    Stripe = require('stripe')(Meteor.settings.stripeSecretKey)
    subscription = Stripe.subscriptions.retrieve Meteor.user().stripeSubscriptionId

    subscription

export stopSubscription = new ValidatedMethod
  name: 'users.stopSubscription'
  validate: null
  run: ->
    if !Meteor.user() || !Meteor.user().stripeSubscriptionId
      return false

    Stripe = require('stripe')(Meteor.settings.stripeSecretKey)
    stripeSubscriptionsDelSync = Meteor.wrapAsync Stripe.subscriptions.del, Stripe.subscriptions
    subscription = stripeSubscriptionsDelSync Meteor.user().stripeSubscriptionId, {at_period_end: true}
    subscription

export checkSubscriptions = new ValidatedMethod
  name: 'users.checkSubscriptions'
  validate: null
  run: ->
    Stripe = require('stripe')(Meteor.settings.stripeSecretKey)
    users = Meteor.users.find stripeSubscriptionId: {$exists: true}
    console.log "Check subsriptions"
    users.forEach (user) ->
      stripeSubscriptionsRetrieveSync = Meteor.wrapAsync Stripe.subscriptions.retrieve, Stripe.subscriptions
      subscription = stripeSubscriptionsRetrieveSync user.stripeSubscriptionId
      if subscription.ended_at
        # Subscription is exired, cancel it
        Meteor.users.update {_id:user._id}, {$unset:{stripeSubscriptionId:1,isPro:1}}
        console.log "Cancelled "+user._id
      else
        console.log "Valid "+user._id


# Get note of all method names on Notes
USERS_METHODS = _.pluck([
  referral
  startTrial
  getSubscription
], 'name')

if Meteor.isServer
  # Only allow 5 notes operations per connection per second
  DDPRateLimiter.addRule {
    name: (name) ->
      _.contains USERS_METHODS, name

    # Rate limit per connection ID
    connectionId: ->
      yes

  }, 5, 1000
