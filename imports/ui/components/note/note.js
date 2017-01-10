import { Template } from 'meteor/templating';
 
import { Notes } from '../../../api/notes/notes.js';
 
import './note.html';
 
Template.note.events({
  'click .toggle-checked'() {
    // Set the checked property to the opposite of its current value
    Notes.update(this._id, {
      $set: { checked: ! this.checked },
    });
  },
  'click .delete'() {
    Meteor.call('notes.remove', this._id);
  },
});

Template.note.helpers({
	'class'() {
		let tags = this.title.match(/#\w+/g);
		let className = '';
		if (!tags) {
			return false;
		}
		tags.forEach(function(tag) {
			className = className+ ' tag-'+tag.substr(1).toLowerCase();
		});
		return className;
	}
});