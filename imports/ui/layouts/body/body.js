import './body.html';

import '../../components/importer/importer.js';

Template.App_body.onCreated(function () {
  Meteor.subscribe('notes.all');
});

Template.App_body.events({
  'click .go-top'(event) {
    event.preventDefault();
    // ANimate
  }
});