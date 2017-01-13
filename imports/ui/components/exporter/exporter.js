import { Template } from 'meteor/templating';
 
import { Notes } from '../../../api/notes/notes.js';
 
import './exporter.jade';

Template.exporter.events({
    exportContent: function () {
        return Meteor.call('notes.export');
    }

});

Template.exporter.events({
  'click input.submit'(event) {
    event.preventDefault();
    Meteor.call('notes.export',function(err,res) {
      $('.exportContent').val(res);
    });
  },
});
