import { Template } from 'meteor/templating';
 
import { Notes } from '../../../api/notes/notes.js';
 
import './note.jade';
 
Template.note.helpers({
  children() {
    return Notes.find({parent: this._id}, {sort: {rank: 1}});
  }
});

Template.note.events({
  'click .delete'(event) {
	event.preventDefault();
    Meteor.call('notes.remove', this._id, function() {
    	App.calculateRank();
    });
  },
  'blur p'(event) {
  	Meteor.call('notes.updateBody',this._id,event.target.innerText);
  },
  'blur div'(event) {
  	Meteor.call('notes.updateTitle',this._id,event.target.innerText);
  },
  'keydown div'(event) {
  	let that = this;
	event.stopImmediatePropagation();
  	switch(event.keyCode) {
  		// Enter
		case 13:
			if (event.shiftKey) {
				// Show the body area
				this.body = 'Yes';
				$(event.currentTarget).siblings('p').show().focus();
			} else {
  				// Chop the text in half at the cursor
  				// put what's on the left in a note on top
  				// put what's to the right in a note below
  				
  				let position = window.getSelection().getRangeAt(0).startOffset;
  				let text = event.currentTarget.innerText;
  				let topNote = text.substr(0,position);
  				let bottomNote = text.substr(position);
  				// Create a new note below the current.
  				Meteor.call('notes.updateTitle',this._id,topNote,function(err,res) {
  					console.log(err,res,that);
	  				Meteor.call('notes.insert',bottomNote,that.rank+.5,that.parent,function(err,res) {
	  					console.log(err,res);
	 	  				if (topNote.length > 0) {
	  						$(event.currentTarget).parent().next().children('div').focus();
	  					}
		  				App.calculateRank();
	  				});
  				});
  			}
  			return false;
  		break;
  		// Tab
  		case 9:
  			event.preventDefault();
  			let parent_id = Blaze.getData($(event.currentTarget).parent().prev().get(0))._id;
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
		if (!this.body) {
			return 'display: none';
		}
	}
});