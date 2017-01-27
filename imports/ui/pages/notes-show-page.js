import { Template } from 'meteor/templating';
import { FlowRouter } from 'meteor/kadira:flow-router';

import { Notes } from '../../api/notes/notes.js';

import { noteRenderHold } from '../launch-screen.js';
import './notes-show-page.html';

// Components used inside the template
import './app-not-found.js';
import '../components/notes-show.js';

Template.Notes_show_page.onCreated(function notesShowPageOnCreated() {
  this.getNoteId = () => FlowRouter.getParam('_id');

  this.autorun(() => {
    this.subscribe('notes.inNote', { parent: this.getNoteId() });
  });
});

Template.Notes_show_page.onRendered(function notesShowPageOnRendered() {
  this.autorun(() => {
    if (this.subscriptionsReady()) {
      noteRenderHold.release();
    }
  });
});

Template.Notes_show_page.helpers({
  // We use #each on an array of one item so that the "note" template is
  // removed and a new copy is added when changing notes, which is
  // important for animation purposes.
  noteIdArray() {
    const instance = Template.instance();
    const noteId = instance.getNoteId();
    return Notes.findOne(noteId) ? [noteId] : [];
  },
  noteArgs(noteId) {
    const instance = Template.instance();
    // By finding the note with only the `_id` field set, we don't create a dependency on the
    // `note.incompleteCount`, and avoid re-rendering the todos when it changes
    const note = Notes.findOne(noteId, { fields: { _id: true } });
    const children = note && note.children();
    return {
      childrenReady: instance.subscriptionsReady(),
      // We pass `note` (which contains the full note, with all fields, as a function
      // because we want to control reactivity. When you check a todo item, the
      // `note.incompleteCount` changes. If we didn't do this the entire note would
      // re-render whenever you checked an item. By isolating the reactiviy on the note
      // to the area that cares about it, we stop it from happening.
      note() {
        return Notes.findOne(noteId);
      },
      children,
    };
  },
});
