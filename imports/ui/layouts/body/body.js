import './body.jade';
import '../../components/importer/importer.js';

Template.App_body.helpers({
    searchTerm: function () {
        return Session.get('searchTerm');
    }
});

Template.App_body.events({
  'keydown .searchForm'(event) {
    if (event.keyCode==13) {
      event.preventDefault();
      window.location.pathname='/search/'+event.target.value;
    }
  },
  'click .searchForm'(event) {
    $(event.target).select();
  },
  'click .searchForm .btn'(event) {
    window.location.pathname='/search/'+$('.searchForm input').val();
  }
});