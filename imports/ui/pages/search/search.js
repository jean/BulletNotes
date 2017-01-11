import './search.jade';

Template.App_search.helpers({
    searchTerm: function () {
        return FlowRouter.getParam('searchTerm');
    }
});
