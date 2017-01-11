import { Template } from 'meteor/templating';
import { ReactiveDict } from 'meteor/reactive-dict';

import { Notes } from '../../../api/notes/notes.js';
 
import './note.jade';
 
Template.note.helpers({
  children() {
  	if (this.showChildren) {
    	return Notes.find({parent: this._id}, {sort: {rank: 1}});
    }
  }
});

Template.note.onCreated(function bodyOnCreated() {
  this.state = new ReactiveDict();
});

Template.note.events({
  'click .title, click .fa-pencil'(event, instance) {
    event.stopImmediatePropagation();
    if (event.originalEvent.target.tagName == 'A') {
      return;
    }
    event.preventDefault();
    instance.state.set('editing', true);
    //console.log($(event.originalEvent.target).parent().find('.title-edit'));
    //setTimeout(function(){$($(event.originalEvent.target).parent().find('.title-edit').get(0)).focus();},100);
    $('input.title-edit').focus();
  },
  'click .fa-trash-o'(event) {
    event.preventDefault();
    Meteor.call('notes.remove', this._id);
  },
  'click .expand'(event) {
    event.stopImmediatePropagation();
    event.preventDefault();
    Meteor.call('notes.showChildren', this._id, ! this.showChildren);
  },
  'blur p'(event) {
  	Meteor.call('notes.updateBody',this._id,event.target.innerText);
  },
  'blur input.title-edit'(event,instance) {
    event.stopImmediatePropagation();
  	Meteor.call('notes.updateTitle',this._id,event.target.value,function(err,res) {
  		// Fix for contenteditable crap here?
      instance.state.set('editing',false);
  	});
  },
  'keydown div'(event) {
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
	  						$(event.currentTarget).parent().parent().next().children('div').focus();
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
  			let parent_id = Blaze.getData($(event.currentTarget).parentsUntil('.notes').prev().get(0))._id;
  			if (event.shiftKey) {
  				Meteor.call('notes.outdent',this._id);
  			} else {
  				Meteor.call('notes.makeChild',this._id,parent_id);
  			}
  			return false;
  		break;
  		// Backspace
  		case 8:
  			if ($(event.currentTarget).length==0) {
  				Meteor.call('notes.remove',this._id);
  			}
  			if (window.getSelection().toString() == "") {
	  			let position = window.getSelection().getRangeAt(0).startOffset;
	  			console.log(event); //return false;
	  			if (position == 0) {
	  				let prev = $(event.currentTarget).parent().parent().prev();
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
  			$(event.currentTarget).parent().parent().prev().children('div').focus();
  		break;
  		// Down
  		case 40:
  			$(event.currentTarget).parent().parent().next().children('div').focus();
  		break;
  		// Escape
  		case 27:
  			$(event.currentTarget).blur();
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
	'expandClass'() {
		if (this.children > 0 && this.showChildren) {
			return 'fa-angle-up btn-primary';
		} else if (this.children > 0) {
			return 'fa-angle-down btn-primary';
		} else {
			return '';
		}
	},
	'bulletClass'() {
		if (this.children > 0) {
			return 'hasChildren';
		}
	},
  'displayTitle'() {
    console.log(this);
    let inputText = this.title;
    var replacedText, replacePattern1, replacePattern2, replacePattern3;

    //URLs starting with http://, https://, or ftp://
    replacePattern1 = /(\b(https?|ftp):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/gim;
    replacedText = inputText.replace(replacePattern1, '<a href="$1" target="_blank">$1</a>');

    //URLs starting with "www." (without // before it, or it'd re-link the ones done above).
    replacePattern2 = /(^|[^\/])(www\.[\S]+(\b|$))/gim;
    replacedText = replacedText.replace(replacePattern2, '$1<a href="http://$2" target="_blank">$2</a>');

    //Change email addresses to mailto:: links.
    replacePattern3 = /(([a-zA-Z0-9\-\_\.])+@[a-zA-Z\_]+?(\.[a-zA-Z]{2,6})+)/gim;
    replacedText = replacedText.replace(replacePattern3, '<a href="mailto:$1">$1</a>');

    let hashtagAndNamePatter = /(^|\s)([#@][a-z\d-]+)/;
    replacedText = replacedText.replace(hashtagAndNamePatter, ' <a href="/search/$2">$2</a> ')

    return replacedText;
  },
  'isEditing'() {
    const instance = Template.instance();
    return instance.state.get('editing');
  }
});