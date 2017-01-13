import { Template } from 'meteor/templating';
 
import { Notes } from '../../../api/notes/notes.js';
 
import './breadcrumbs.jade';

Template.breadcrumbs.helpers({
  parents() {
    let parents = [];
    if (this.noteId) {
      let note = Notes.findOne(this.noteId);
      let parent = Notes.findOne(note.parent);
      while (parent) {
        parents.unshift(parent);
        parent = Notes.findOne(parent.parent);
      }
    }
    return parents;
  }
});