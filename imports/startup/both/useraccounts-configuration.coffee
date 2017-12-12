import { FlowRouter } from 'meteor/kadira:flow-router';
import { AccountsTemplates } from 'meteor/useraccounts:core';
import { insert } from '/imports/api/notes/methods.coffee';
import { Meteor } from 'meteor/meteor';
mySubmitFunc = (error, state) ->
  if !error
    if state == 'signIn'
      FlowRouter.go '/'
      # Successfully logged in
    if state == 'signUp'
      insert.call
        'title': 'Welcome!  🎉  Click on any note and start typing!'
        'rank': 1
        'showChildren': true
      , (err, res) ->
        console.log err, res
        insert.call
          'title': 'You can nest notes under each other'
          'rank': 10
          'parent': res._id
        insert.call
          'title': 'As many as you want'
          'rank': 20
          'parent': res._id
        insert.call
          'title': 'You can zoom into notes by clicking the dot, and rearrange them by dragging the dot'
          'rank': 21
          'parent': res._id
        insert.call
          'title': 'You can use <b>bold</b> and <i>italics</i>'
          'rank': 30
          'parent': res._id
        insert.call
          'title': 'You can mark them using hashtags #tips'
          'rank': 31
          'parent': res._id
        insert.call
          'title': 'You can color them #blue'
          'rank': 32
          'parent': res._id
        insert.call
          'title': 'And you can mark some as #done'
          'rank': 40
          'parent': res._id
          'complete': true

      insert.call
        'title': 'For more help getting started check out the User Guide link in the footer. #tips'
        'rank': 20
      FlowRouter.go '/'

    if state == 'signOut'
      FlowRouter.go '/intro'
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
