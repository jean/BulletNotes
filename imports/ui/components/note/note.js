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
  'click .expand'(event) {
    event.stopImmediatePropagation();
    event.preventDefault();
    Meteor.call('notes.showChildren', this._id, ! this.showChildren);
  },
  'click p.body'(event,instance) {
    event.stopImmediatePropagation();
    instance.state.set('editingBody',true);
    instance.state.set('editing',false);
    setTimeout(function(){$('textarea').select();},10);
  },
  'blur p.body'(event, instance) {
    event.stopImmediatePropagation();
    let body = Template.note.stripTags(event.target.innerHTML);
    Meteor.call('notes.updateBody',this._id,body,function (err,res) {
      instance.state.set('editingBody',false);
    });
  },
  'blur div.title'(event,instance) {
    let that = this;
    event.stopImmediatePropagation();
    let title = Template.note.stripTags(event.target.innerHTML);
    if (title != this.title) {
      event.target.innerHTML='';
      Meteor.call('notes.updateTitle',this._id,title,function(err,res){
        that.title = title;
      });
    }
  },
  'keydown div.title'(event) {
    let note = this;
    event.stopImmediatePropagation();
    switch(event.keyCode) {
      // Enter
      case 13:
        event.preventDefault();
        if (event.shiftKey) {
          // Edit the body
          note.body = ' yes ';
        } else {
          // Chop the text in half at the cursor
          // put what's on the left in a note on top
          // put what's to the right in a note below
          console.log(window.getSelection().anchorOffset);
          console.log(event); //return;
          let position = event.target.selectionStart;
          let text = event.target.innerHTML;
          let topNote = text.substr(0,position);
          let bottomNote = text.substr(position);
          // Create a new note below the current.
          Meteor.call('notes.updateTitle',note._id,topNote,function(err,res) {
            Meteor.call('notes.insert','',note.rank+.5,note.parent,function(err,res) {
              App.calculateRank();
              setTimeout(function(){$(event.target).closest('.note').next().find('.title').focus();},50);
            });
          });
        }
      break;
      // Tab
      case 9:
        event.preventDefault();
        let parent_id = Blaze.getData($(event.currentTarget).closest('.note').prev().get(0))._id;
        //console.log(parent_id); return;
        if (event.shiftKey) {
          Meteor.call('notes.outdent',this._id);
        } else {
          Meteor.call('notes.makeChild',this._id,parent_id);
        }
        return;
      break;
      // Backspace
      case 8:
        //if ($(event.currentTarget).length==0) {
        //  Meteor.call('notes.remove',this._id);
        //}
        if (window.getSelection().toString() == "") {
          let position = event.target.selectionStart
          if (position == 0) {
            // We're at the start of the note, add this to the note above, and remove it.
            console.log(event.target.value);
            let prev = $(event.currentTarget).parentsUntil('#notes').prev();
            console.log(prev);
            let prevNote = Blaze.getData(prev.get(0));
            console.log(prevNote);
            let note = this;
            console.log(note);
            Meteor.call('notes.updateTitle',prevNote._id,prevNote.title+event.target.value,function(err,res) {
             Meteor.call('notes.remove',note._id,function(err,res) {
              // Moves the caret to the correct position
              prev.find('.title').trigger('click');
            });
           });
          }
        }
        break;
      // Up
      case 38:
        $(event.currentTarget).closest('.note').prev().find('div.title').focus();
      break;
      // Down
      case 40:
        $(event.currentTarget).closest('.note').next().find('div').focus();
      break;
      // Escape
      case 27:
        $(event.currentTarget).blur();
      break;
    }
  }
});
Template.note.stripTags = function(inputText) {
  if (!inputText) {
    return;
  }
  inputText = inputText.replace(/<\/?span[^>]*>/g,"");
  inputText = inputText.replace(/<\/?a[^>]*>/g,"");
  return inputText;
}
Template.note.formatText = function(inputText) {
  if (!inputText) {
    return;
  }
  var replacedText, replacePattern1, replacePattern2, replacePattern3;

  //URLs starting with http://, https://, or ftp://
  replacePattern1 = /(\b(https?|ftp):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/gim;
  replacedText = inputText.replace(replacePattern1, '<a href="$1" target="_blank">$1</a>');

  //URLs starting with "www." (without // before it, or it'd re-link the ones done above).
  replacePattern2 = /(^|[^\/])(www\.[\S]+(\b|$))/gim;
  replacedText = replacedText.replace(replacePattern2, '<a href="http://$2" target="_blank">$2</a>');

  //Change email addresses to mailto:: links.
  replacePattern3 = /(([a-zA-Z0-9\-\_\.])+@[a-zA-Z\_]+?(\.[a-zA-Z]{2,6})+)/gim;
  replacedText = replacedText.replace(replacePattern3, '<a href="mailto:$1">$1</a>');

  let hashtagPattern = /(^|\s)(([#])([a-z\d-]+))/gim;
  replacedText = replacedText.replace(hashtagPattern, function(match, p1, p2, p3, p4, offset, string) {
    let className = p4.toLowerCase();
    return ' <a href="/search/%23'+p4+'" class="tagLink tag-'+className+'">#'+p4+'</a>'
  });

  let namePattern = /(^|\s)(([@])([a-z\d-]+))/gim;
  replacedText = replacedText.replace(namePattern, ' <a href="/search/%40$4" class="at-$4">@$4</a>');

  let searchTerm = Session.get('searchTerm');
  replacedText = replacedText.replace(searchTerm, "<span class='searchResult'>$&</span>");
  replacedText = replacedText.replace(/&nbsp;/gim, " ");
  return replacedText;
}
Template.note.helpers({
  'class'() {
    let className = 'level-'+(this.level-Session.get('level'));
    let tags = this.title.match(/#\w+/g);
    if (tags) {
      tags.forEach(function(tag) {
        className = className + ' tag-'+(tag.substr(1)).toLowerCase();
      });
    }
    return className;
  },
  'style'() {
    let margin = (this.level-Session.get('level'));
    return 'margin-left: '+margin+'em';
  },
  'expandClass'() {
    if (this.children > 0 && this.showChildren) {
      return 'fa-angle-up';
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
    return Template.note.formatText(this.title);
  },
  'displayBody'() {
    return Template.note.formatText(this.body);
  },
  'isEditing'() {
    const instance = Template.instance();
    return instance.state.get('editing');
  },
  'isEditingBody'() {
    const instance = Template.instance();
    return instance.state.get('editingBody');
  }
});