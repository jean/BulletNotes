import { Notes } from '/imports/api/notes/notes.js';
import { Meteor } from 'meteor/meteor';
import './notes.jade';
import '../note/note.js'

newNoteText = "New note...";

Template.notes.onCreated(function () {
  Meteor.subscribe('notes.all');
});

Template.notes.helpers({
  notes() {
    return Notes.find({}, {sort: {rank: 1}});
  },
  newNoteText() {
    return newNoteText;
  }
});

Template.notes.events({
  'focus #new-note'(event) {
    console.log(event);
    if (event.currentTarget.innerText == newNoteText) {
      event.currentTarget.innerText = '';
    }
  },
  'keyup #new-note'(event) {
    switch (event.keyCode) {
      case 13:
        Meteor.call('notes.insert', event.currentTarget.innerText, (error) => {
          if (error) {
            alert(error.error);
          } else {
            $('#new-note').text(newNoteText);
          }
        });
        break;
      case 27:
        $('#new-note').text(newNoteText).blur();
    }
  },
  'blur #new-note'(event) {
    if (event.currentTarget.innerText == '') {
      $('#new-note').text(newNoteText);
    }
  }
});

Template.notes.rendered = function() {
    this.$('#notes').sortable({
        handle: '.delete',
        stop: function(el, ui) {
          console.log('sort');
          $('#notes li').each(function(ii, el){
            console.log(el,ii);
            console.log(Blaze.getData(this));
            var id = Blaze.getData(this)._id;
            console.log(id,ii);
            //Notes.update(id, {$set:{rank:ii+1}});
            Meteor.call('notes.update',id,Blaze.getData(this).title,ii+1);
          });
        }
    })
  }

