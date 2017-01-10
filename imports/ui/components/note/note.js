import { Template } from 'meteor/templating';
 
import { Notes } from '../../../api/notes/notes.js';
 
import './note.jade';
 
Template.note.helpers({
  children() {
  	if (this.showChildren) {
    	return Notes.find({parent: this._id}, {sort: {rank: 1}});
    }
  }
});

Template.note.events({
	'click .bullet'(event) {
		event.stopImmediatePropagation();
		event.preventDefault();
		Meteor.call('notes.showChildren', this._id, ! this.showChildren);
	},
  'blur p'(event) {
  	Meteor.call('notes.updateBody',this._id,event.target.innerText);
  },
  'blur div.title'(event) {
  	Meteor.call('notes.updateTitle',this._id,event.target.innerText);
  },
  'keydown div'(event) {
  	console.log(event);
  	let note = this;
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
  				Meteor.call('notes.updateTitle',note._id,topNote,function(err,res) {
	  				Meteor.call('notes.insert',bottomNote,note.rank+.5,note.parent,note.level,function(err,res) {
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
  		// Backspace
  		case 8:
  			if (this.title.length==0) {
  				Meteor.call('notes.remove',this._id);
  			}
  			if (window.getSelection().toString() == "") {
	  			let position = window.getSelection().getRangeAt(0).startOffset;
	  			console.log(event); //return false;
	  			if (position == 0) {
	  				let prev = $(event.currentTarget).parent().prev();
	  				let prevNote = Blaze.getData(prev.get(0));
	  				let note = this;
	 				Meteor.call('notes.updateTitle',prevNote._id,prevNote.title+$(event.currentTarget).get(0).innerText,function(err,res) {
	 					Meteor.call('notes.remove',note._id,function(err,res) {
	 						// This bit just moves the caret to the correct position
	 						prev.children('div').focus();
							let ele = prev.children('div').get(0);
							let rng = document.createRange();
							let sel = window.getSelection();
							rng.setStart(ele.childNodes[0], prevNote.title.length);
							rng.collapse(true);
							sel.removeAllRanges();
							sel.addRange(rng);
							ele.focus();
	 					});
	 				});
	  			}
	  		}
  		break;
  		// Up
  		case 38:
  			$(event.currentTarget).parent().prev().children('div').focus();
  		break;
  		// Down
  		case 40:
  			$(event.currentTarget).parent().next().children('div').focus();
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
	},
	'bulletClass'() {
		if (this.children > 0) {
			return 'hasChildren';
		}
	}
});