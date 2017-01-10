import { Template } from 'meteor/templating';
 
import { Notes } from '../../../api/notes/notes.js';
 
import './note.jade';
 
Template.note.helpers({
  children() {
    return Notes.find({parent: this._id}, {sort: {rank: 1}});
  }
});

Template.note.events({
  'click .toggle-checked'() {
    // Set the checked property to the opposite of its current value
    Notes.update(this._id, {
      $set: { checked: ! this.checked },
    });
  },
  'click .delete'() {
    Meteor.call('notes.remove', this._id, function() {
    	App.calculateRank();
    });
  },
  'blur p'(event) {
  	Meteor.call('notes.updateBody',this._id,event.target.innerText);
  },
  'blur div'(event) {
  	Meteor.call('notes.update',this._id,event.target.innerText,this.rank);
  },
  'keydown div'(event) {
	event.stopImmediatePropagation();
  	switch(event.keyCode) {
  		// Enter
		case 13:
			if (event.shiftKey) {
				// Show the body area
				this.body = 'Yes';
				$(event.currentTarget).siblings('p').show().focus();
				console.log("show body",this);

			} else {
  				$(event.target).blur();
  			}
  			return false;
  		break;
  		// Tab
  		case 9:
  			event.preventDefault();
  			let parent_id = Blaze.getData($(event.currentTarget).parent().prev().get(0))._id;
  			console.log(this._id,parent_id);
  			if (event.shiftKey) {
  				Meteor.call('notes.outdent',this._id);
  			} else {
  				Meteor.call('notes.makeChild',this._id,parent_id);
  			}
  			return false;
  		break;
  	}
  }
});

Template.note.helpers({
	'class'() {
		let className = 'level-'+this.level;
		let tags = this.title.match(/#\w+/g);
		if (tags) {
			tags.forEach(function(tag) {
				className = className + ' tag-'+tag.substr(1).toLowerCase();
			});
		}
		return className;
	},
	'style'() {
		let margin = this.level;
		return 'margin-left: '+margin+'em';
	},
	'bodyStyle'() {
		console.log(this);
		if (!this.body) {
			return 'display: none';
		}
	}
});