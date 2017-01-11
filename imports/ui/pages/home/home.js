import './home.jade';

import '../../components/notes/notes.js';

Template.App_home.onCreated(function () {
  Session.set('searchTerm','');
});