import './body.html';

Template.App_body.onCreated(function () {
  Meteor.subscribe('notes.all');
});

Template.App_body.events({
  'click .go-top'(event) {
    event.preventDefault();
    // ANimate
  }
});