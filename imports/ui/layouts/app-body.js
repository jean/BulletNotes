/* global alert */

import { Meteor } from 'meteor/meteor';
import { ReactiveVar } from 'meteor/reactive-var';
import { ReactiveDict } from 'meteor/reactive-dict';
import { Template } from 'meteor/templating';
import { ActiveRoute } from 'meteor/zimme:active-route';
import { FlowRouter } from 'meteor/kadira:flow-router';
import { TAPi18n } from 'meteor/tap:i18n';
import { T9n } from 'meteor/softwarerero:accounts-t9n';
import { _ } from 'meteor/underscore';
import { $ } from 'meteor/jquery';

import { Notes } from '/imports/api/notes/notes.coffee';
import { insert } from '/imports/api/notes/methods.coffee';

import '../components/loading/loading.coffee';
import './app-body.jade';

const CONNECTION_ISSUE_TIMEOUT = 5000;

// A store which is local to this file?
const showConnectionIssue = new ReactiveVar(false);

Meteor.startup(() => {
  // Only show the connection error box if it has been 5 seconds since
  // the app started
  setTimeout(() => {
    // FIXME:
    // Launch screen handle created in lib/router.js
    // dataReadyHold.release();

    // Show the connection error box
    showConnectionIssue.set(true);
  }, CONNECTION_ISSUE_TIMEOUT);
});

Template.App_body.onCreated(function appBodyOnCreated() {
  console.log("App_body created");
  this.subscribe('notes.all');

  this.state = new ReactiveDict();
  this.state.setDefault({
    menuOpen: false,
    userMenuOpen: false,
  });

  setTimeout(function() {
    $('.betaWarning').fadeOut();
  },5000);

  setTimeout(function() {
    $('.devWarning').fadeOut();
  },10000);
});

Template.App_body.helpers({
  menuOpen() {
    const instance = Template.instance();
    return instance.state.get('menuOpen') && 'menu-open';
  },
  wrapClasses() {
      classname = '';
      if (Meteor.isCordova) {
        classname += 'cordova';
      }
      if (Meteor.settings.public.dev) {
        classname += ' dev';
      }
      return classname;
  },
  displayName() {
    let displayName = '';
    if (Meteor.user().emails) {
      const email = Meteor.user().emails[0].address;
      displayName = email.substring(0, email.indexOf('@'));
    } else {
      displayName = Meteor.user().profile.name;
    }
    return displayName;
  },
  userMenuOpen() {
    const instance = Template.instance();
    return instance.state.get('userMenuOpen');
  },
  dev() {
    return Meteor.settings.public.dev;
  },
  notes() {
    return Notes.find({
      favorite: true
    },{sort:{favoritedAt:-1}});
  },
  activeNoteClass(note) {
    const active = ActiveRoute.name('Notes.show')
      && FlowRouter.getParam('_id') === note._id;

    return active && 'active';
  },
  connected() {
    if (showConnectionIssue.get()) {
      return Meteor.status().connected;
    }

    return true;
  },
  templateGestures: {
    'swipeleft .cordova'(event, instance) {
      instance.state.set('menuOpen', false);
    },
    'swiperight .cordova'(event, instance) {
      instance.state.set('menuOpen', true);
    },
  },
  languages() {
    return _.keys(TAPi18n.getLanguages());
  },
  isActiveLanguage(language) {
    return (TAPi18n.getLanguage() === language);
  },
  expandClass() {
    const instance = Template.instance();
    return (instance.state.get('menuOpen') ? 'expanded' : '');
  }
});

Template.App_body.events({
  'click .js-menu'(event, instance) {
    instance.state.set('menuOpen', !instance.state.get('menuOpen'));
  },

  'click .content-overlay'(event, instance) {
    instance.state.set('menuOpen', false);
    event.preventDefault();
  },

  'click .js-user-menu'(event, instance) {
    instance.state.set('userMenuOpen', !instance.state.get('userMenuOpen'));
    // stop the menu from closing
    event.stopImmediatePropagation();
  },

  'click #menu a'(event, instance) {
    instance.state.set('menuOpen', false);
    instance.state.set('userMenuOpen', false);
  },

  'click .js-logout'() {
    Meteor.logout();

    // if we are on a private note, we'll need to go to a public one
    if (ActiveRoute.name('Notes.show')) {
      // TODO -- test this code path
      const note = Notes.findOne(FlowRouter.getParam('_id'));
      if (note.userId) {
        FlowRouter.go('Notes.show', Notes.findOne({ userId: { $exists: false } }));
      }
    }
  },

  'click .js-new-note'() {
    const noteId = insert.call({ title: 'New list 1', level: 0 }, (err) => {
      if (err) {
        console.log(err);
        // At this point, we have already redirected to the new note page, but
        // for some reason the note didn't get created. This should almost never
        // happen, but it's good to handle it anyway.
        FlowRouter.go('App.home');
        alert(TAPi18n.__('layouts.appBody.newNoteError')); // eslint-disable-line no-alert
      }
    });

    FlowRouter.go('Notes.show', { _id: noteId });
  },

  'click .js-toggle-language'(event) {
    const language = $(event.target).html().trim();
    T9n.setLanguage(language);
    TAPi18n.setLanguage(language);
  },
});
