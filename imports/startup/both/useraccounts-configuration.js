import { FlowRouter } from 'meteor/kadira:flow-router';
import { AccountsTemplates } from 'meteor/useraccounts:core';
import { insert } from '/imports/api/notes/methods.coffee';
import { Meteor } from 'meteor/meteor';

/**
 * The useraccounts package must be configured for both client and server to work properly.
 * See the Guide for reference (https://github.com/meteor-useraccounts/core/blob/master/Guide.md)
 */

 var mySubmitFunc = function(error, state){
  if (!error) {
    if (state === "signIn") {
      // Successfully logged in
      // ...
    }
    if (state === "signUp") {
        insert.call({"title":"Welcome!  🎉  Click on this note, hit enter, and start typing.","rank":1});
    }
    if (state === "signOut") {
        FlowRouter.go('/');
    }
  }
};

AccountsTemplates.configure({
    onSubmitHook: mySubmitFunc
});

AccountsTemplates.configure({
  showForgotPasswordLink: true,
  defaultTemplate: 'Auth_page',
  defaultLayout: 'App_body',
  defaultContentRegion: 'main',
  defaultLayoutRegions: {},
});

AccountsTemplates.configureRoute('signIn', {
  name: 'signin',
  path: '/signin',
});

AccountsTemplates.configureRoute('signUp', {
  name: 'join',
  path: '/join',
});

AccountsTemplates.configureRoute('forgotPwd');

AccountsTemplates.configureRoute('resetPwd', {
  name: 'resetPwd',
  path: '/reset-password',
});

if (Meteor.isServer) {
  Accounts.onCreateUser((options, user) => {
    console.log(options, user );

    // We still want the default hook's 'profile' behavior.
    if (options.profile) {
      user.profile = options.profile;
    }
    
    // Don't forget to return the new user object at the end!
    return user;
  });
}