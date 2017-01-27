/* global confirm */

import { Meteor } from 'meteor/meteor';
import { Template } from 'meteor/templating';
import { Mongo } from 'meteor/mongo';
import { ReactiveDict } from 'meteor/reactive-dict';
import { Tracker } from 'meteor/tracker';
import { $ } from 'meteor/jquery';
import { FlowRouter } from 'meteor/kadira:flow-router';
import { SimpleSchema } from 'meteor/aldeed:simple-schema';
import { TAPi18n } from 'meteor/tap:i18n';

import './notes-show.html';

// Component used in the template
import './notes-item.js';

import {
  updateName,
  makePublic,
  makePrivate,
  remove,
  insert,
} from '../../api/notes/methods.js';

import { displayError } from '../lib/errors.js';

Template.Notes_show.onCreated(function noteShowOnCreated() {
  this.subscribe('notes.children', this.data.note()._id);

  this.autorun(() => {
    new SimpleSchema({
      note: { type: Function },
      childrenReady: { type: Boolean },
      children: { type: Mongo.Cursor },
    }).validate(Template.currentData());
  });

  this.state = new ReactiveDict();
  this.state.setDefault({
    editing: false,
    editingNote: false,
  });

  this.saveNote = () => {
    this.state.set('editing', false);

    const newName = this.$('[name=name]').val().trim();
    if (newName) {
      updateName.call({
        noteId: this.data.note()._id,
        newName,
      }, displayError);
    }
  };

  this.editNote = () => {
    this.state.set('editing', true);

    // force the template to redraw based on the reactive change
    Tracker.flush();
    // We need to wait for the fade in animation to complete to reliably focus the input
    Meteor.setTimeout(() => {
      this.$('.js-edit-form input[type=text]').focus();
    }, 400);
  };

  this.deleteNote = () => {
    const note = this.data.note();
    const message = `${TAPi18n.__('notes.remove.confirm')} "${note.name}"?`;

    if (confirm(message)) { // eslint-disable-line no-alert
      remove.call({
        noteId: note._id,
      }, displayError);

      FlowRouter.go('App.home');
      return true;
    }

    return false;
  };

  this.toggleNotePrivacy = () => {
    const note = this.data.note();
    if (note.userId) {
      makePublic.call({ noteId: note._id }, displayError);
    } else {
      makePrivate.call({ noteId: note._id }, displayError);
    }
  };
});

Template.Notes_show.helpers({
  noteArgs(note) {
    const instance = Template.instance();
    return {
      note,
      editing: instance.state.equals('editingNote', note._id),
      onEditingChange(editing) {
        instance.state.set('editingNote', editing ? note._id : false);
      },
    };
  },
  editing() {
    const instance = Template.instance();
    return instance.state.get('editing');
  },
});

Template.Notes_show.events({
  'click .js-cancel'(event, instance) {
    instance.state.set('editing', false);
  },

  'keydown input[type=text]'(event) {
    // ESC
    if (event.which === 27) {
      event.preventDefault();
      $(event.target).blur();
    }
  },

  'blur input[type=text]'(event, instance) {
    // if we are still editing (we haven't just clicked the cancel button)
    if (instance.state.get('editing')) {
      instance.saveNote();
    }
  },

  'submit .js-edit-form'(event, instance) {
    event.preventDefault();
    instance.saveNote();
  },

  // handle mousedown otherwise the blur handler above will swallow the click
  // on iOS, we still require the click event so handle both
  'mousedown .js-cancel, click .js-cancel'(event, instance) {
    event.preventDefault();
    instance.state.set('editing', false);
  },

  // This is for the mobile dropdown
  'change .note-edit'(event, instance) {
    const target = event.target;
    if ($(target).val() === 'edit') {
      instance.editNote();
    } else if ($(target).val() === 'delete') {
      instance.deleteNote();
    } else {
      instance.toggleNotePrivacy();
    }

    target.selectedIndex = 0;
  },

  'click .js-edit-note'(event, instance) {
    instance.editNote();
  },

  'click .js-toggle-note-privacy'(event, instance) {
    instance.toggleNotePrivacy();
  },

  'click .js-delete-note'(event, instance) {
    instance.deleteNote();
  },

  'click .js-note-add'(event, instance) {
    instance.$('.js-note-new input').focus();
  },

  'submit .js-note-new'(event) {
    event.preventDefault();

    const $input = $(event.target).find('[type=text]');
    if (!$input.val()) {
      return;
    }

    insert.call({
      parent: this.note()._id,
      title: $input.val(),
    }, displayError);

    $input.val('');
  },
});
