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
  'blur div'(event) {
  	Meteor.call('notes.update',this._id,event.target.innerText,this.rank);
  },
  'keydown div'(event) {
  	console.log(event);
  	switch(event.keyCode) {
		case 13:
			event.preventDefault();
  			$(event.target).blur();
  			return false;
  		break;
  		case 9:
  			event.preventDefault();
  			if (event.shiftKey) {
  				Meteor.call('notes.outdent',this._id)
  			} else {
  				Meteor.call('notes.indent',this._id);
  			}
  			return false;
  		break;
  	}
  }
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
	},
	'style'() {
		let margin = this.level;
		return 'margin-left: '+margin+'em';
	}
});