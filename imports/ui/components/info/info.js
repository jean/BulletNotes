import { Notes } from '/imports/api/notes/notes.js';
import { Meteor } from 'meteor/meteor';
import './info.html';

Template.info.onCreated(function () {
  Meteor.subscribe('notes.all');
});

Template.info.helpers({
  notes() {
    return Notes.find({}, {sort: {rank: 1}});
  },
});

Template.info.events({
  'submit .info-note-add'(event) {
    event.preventDefault();

    const target = event.target;
    const title = target.title;

    Meteor.call('notes.insert', title.value, (error) => {
      if (error) {
        alert(error.error);
      } else {
        title.value = '';
      }
    });
  },
  'click .delete'() {
    Meteor.call('notes.remove', this._id);
  }
});

Template.info.rendered = function() {
    this.$('#notes').sortable({
        stop: function(el, ui) {
          $('.note').each(function(ii, el){
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

