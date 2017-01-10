import './body.html';

Template.App_body.onCreated(function () {
  Meteor.subscribe('notes.all');
});