/* eslint-disable prefer-arrow-callback */

import { Meteor } from 'meteor/meteor';
import { SimpleSchema } from 'meteor/aldeed:simple-schema';

import { Notes } from '../notes.js';

Meteor.publishComposite('notes.inNote', function notesInNote(params) {
  new SimpleSchema({
    noteId: { type: String },
  }).validate(params);

  const { noteId } = params;
  const userId = this.userId;

  return {
    find() {
      const query = {
        _id: noteId,
        $or: [{ userId: { $exists: false } }, { userId }],
      };

      // We only need the _id field in this query, since it's only
      // used to drive the child queries to get the notes
      const options = {
        fields: { _id: 1 },
      };

      return Notes.find(query, options);
    },

    children: [{
      find(note) {
        return Notes.find({ noteId: note._id }, { fields: Notes.publicFields });
      },
    }],
  };
});
