import { Notes } from '/imports/api/notes/notes.js';
import { Meteor } from 'meteor/meteor';

import './notes.jade';
import '../note/note.js'
import '../breadcrumbs/breadcrumbs.js'

newNoteText = "New note...";

Template.notes.onCreated(function () {
  if (Template.currentData().searchTerm) {
    Meteor.subscribe('notes.search', Template.currentData().searchTerm);
  } else {
    Meteor.subscribe('notes.all');
  }
});

Template.notes.helpers({
  focusedNoteTitle() {
    if (Template.currentData().noteId) {
      return Notes.findOne(Template.currentData().noteId).title;
    } else {
      return 'Home';
    }
  },
  notes() {
    if (Template.currentData().noteId) {
      let note = Notes.findOne({parent:Template.currentData().noteId}, {sort: {rank: 1}});
      Session.set('level',note.level);
      return Notes.find({parent:Template.currentData().noteId}, {sort: {rank: 1}});
    } else if (Template.currentData().searchTerm) {
      Session.set('level',0);
      return Notes.find({});
    } else {
      Session.set('level',0);
      return Notes.find({parent: null}, {sort: {rank: 1}});
    }
  },
  newNoteText() {
    return newNoteText;
  },
  focusedNote() {
    return Notes.findOne(Template.currentData().noteId);
  }
});

Template.notes.events({
  'focus #new-note'(event) {
    if (event.currentTarget.innerText == newNoteText) {
      event.currentTarget.innerText = '';
    }
  },
  'keyup #new-note'(event) {
    switch (event.keyCode) {
      // Enter
      case 13:
        Meteor.call('notes.insert', event.currentTarget.innerText, null, Template.currentData().noteId, (error) => {
          if (error) {
            alert(error.error);
          } else {
            $('#new-note').text('');
          }
        });
        break;
      // Escape
      case 27:
        $('#new-note').text(newNoteText).blur();
      break;
      case 38:
        $(event.currentTarget).closest('.note').prev().find('div.title').focus();
      break;
    }
  },
  'blur #new-note'(event) {
    if (event.currentTarget.innerText == '') {
      $('#new-note').text(newNoteText);
    }
  }
});

App = {};
App.calculateRank = function() {
  let levelCount = 0;
  let maxLevel = 6;
  while (levelCount < maxLevel) {
    $('#notes .level-'+levelCount).each(function(ii, el){
      var id = Blaze.getData(this)._id;
      Meteor.call('notes.updateRank',id,ii+1);
    });
    levelCount++;
  }
}

Template.notes.rendered = function() {
  this.$('#notes').sortable({
      handle: '.fa-ellipsis-v',
      stop: function(el, ui) {
        let note = Blaze.getData($(el.originalEvent.target).closest('.note').get(0));
        let parent_note = Blaze.getData($(el.originalEvent.target).closest('.note').prev().get(0));
        Meteor.call('notes.makeChild',note._id,parent_note._id,function(err,res) {
          App.calculateRank();
        });
      }
  });
}
