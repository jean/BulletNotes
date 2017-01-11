import './search.jade';

Template.App_search.onCreated(function () {
  Session.set('searchTerm',FlowRouter.getParam('searchTerm'));
});

Template.App_search.helpers({
    searchTerm: function () {
        return Session.get('searchTerm');
    }
});
