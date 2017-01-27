import { Meteor } from 'meteor/meteor';
import { _ } from 'meteor/underscore';
import { ValidatedMethod } from 'meteor/mdg:validated-method';
import { SimpleSchema } from 'meteor/aldeed:simple-schema';
import { DDPRateLimiter } from 'meteor/ddp-rate-limiter';

import { Notes } from './notes.js';

export const insert = new ValidatedMethod({
  name: 'notes.insert',
  validate: Notes.simpleSchema().pick(['title','parent']).validator({ clean: true, filter: false }),
  run({ title, parent }) {
    // const note = Notes.findOne(noteId);

    // if (note.isPrivate() && note.userId !== this.userId) {
    //   throw new Meteor.Error('notes.insert.accessDenied',
    //     'Cannot add notes to a private note that is not yours');
    // }
    const note = {
      title,
      parent,
      owner: this.userId,
      createdAt: new Date(),
    };

    Notes.insert(note);
  },
});

export const updateTitle = new ValidatedMethod({
  name: 'notes.updateTitle',
  validate: new SimpleSchema({
    noteId: Notes.simpleSchema().schema('_id'),
    newTitle: Notes.simpleSchema().schema('title'),
  }).validator({ clean: true, filter: false }),
  run({ noteId, newTitle }) {
    // This is complex auth stuff - perhaps denormalizing a userId onto notes
    // would be correct here?
    const note = Notes.findOne(noteId);

    if (!note.editableBy(this.userId)) {
      throw new Meteor.Error('notes.updateTitle.accessDenied',
        'Cannot edit notes in a private note that is not yours');
    }

    Notes.update(noteId, {
      $set: {
        title: (_.isUndefined(newTitle) ? null : newTitle),
      },
    });
  },
});

export const remove = new ValidatedMethod({
  name: 'notes.remove',
  validate: new SimpleSchema({
    noteId: Notes.simpleSchema().schema('_id'),
  }).validator({ clean: true, filter: false }),
  run({ noteId }) {
    const note = Notes.findOne(noteId);

    if (!note.editableBy(this.userId)) {
      throw new Meteor.Error('notes.remove.accessDenied',
        'Cannot remove notes in a private note that is not yours');
    }

    Notes.remove(noteId);
  },
});

// Get note of all method names on Notes
const NOTES_METHODS = _.pluck([
  insert,
  updateTitle,
  remove,
], 'name');

if (Meteor.isServer) {
  // Only allow 5 notes operations per connection per second
  DDPRateLimiter.addRule({
    name(name) {
      return _.contains(NOTES_METHODS, name);
    },

    // Rate limit per connection ID
    connectionId() { return true; },
  }, 5, 1000);
}
