import { FlowRouter } from 'meteor/kadira:flow-router';
import { AccountsTemplates } from 'meteor/useraccounts:core';
import { insert } from '/imports/api/notes/methods.coffee';
import { Meteor } from 'meteor/meteor';
mySubmitFunc = (error, state) ->
  if !error
    # if state == 'signIn'
      # Successfully logged in
    if state == 'signUp'
      insert.call
        'title': 'Welcome!  🎉  Click on any note and start typing!'
        'rank': 1
        'showChildren': true
      , (err, res) ->
        insert.call
          'title': 'You can nest notes under each other'
          'rank': 10
          'parent': res
        insert.call
          'title': 'As many as you want'
          'rank': 20
          'parent': res
        insert.call
          'title': 'You can zoom into notes by clicking the dot, and rearrange them by dragging the dot'
          'rank': 21
          'parent': res
        insert.call
          'title': 'You can use <b>bold</b> and <i>italics</i>'
          'rank': 30
          'parent': res
        insert.call
          'title': 'You can mark them using hashtags #tips'
          'rank': 31
          'parent': res
        insert.call
          'title': 'You can color them #blue'
          'rank': 32
          'parent': res
        insert.call
          'title': 'And you can mark some as #done'
          'rank': 40
          'parent': res
          'complete': true

      insert.call
        'title': 'For more help getting started check out the User Guide link in the footer. #tips'
        'rank': 20

    if state == 'signOut'
      FlowRouter.go '/'
  return

AccountsTemplates.configure onSubmitHook: mySubmitFunc
AccountsTemplates.configure
  showForgotPasswordLink: true
  defaultTemplate: 'Auth_page'
  defaultLayout: 'App_body'
  defaultContentRegion: 'main'
  defaultLayoutRegions: {}
AccountsTemplates.configureRoute 'signIn',
  name: 'signin'
  path: '/signin'
AccountsTemplates.configureRoute 'signUp',
  name: 'join'
  path: '/join'
AccountsTemplates.configureRoute 'forgotPwd'
AccountsTemplates.configureRoute 'resetPwd',
  name: 'resetPwd'
  path: '/reset-password'
if Meteor.isServer
  Accounts.onCreateUser (options, user) ->
    # We still want the default hook's 'profile' behavior.
    if options.profile
      user.profile = options.profile
    # Don't forget to return the new user object at the end!
    user
