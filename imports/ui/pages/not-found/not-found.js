import './not-found.jade';

Template.App_notFound.onCreated(function () {
  Session.set('searchTerm','');
});