import { FlowRouter } from 'meteor/kadira:flow-router';
import { BlazeLayout } from 'meteor/kadira:blaze-layout';

// Import needed templates
import '../../ui/layouts/body/body.js';
import '../../ui/pages/home/home.js';
import '../../ui/pages/view-note/view-note.js';
import '../../ui/pages/search/search.js';
import '../../ui/pages/not-found/not-found.js';

// Set up all routes in the app
FlowRouter.route('/', {
  name: 'App.home',
  action() {
    BlazeLayout.render('App_body', { main: 'App_home' });
  },
});

FlowRouter.route('/note/:noteId', {
  name: 'App.viewNote',
  action() {
    BlazeLayout.render('App_body', { main: 'App_viewNote' });
  },
});

FlowRouter.route('/search/:searchTerm', {
  name: 'App.search',
  action() {
    BlazeLayout.render('App_body', { main: 'App_search' });
  },
});

FlowRouter.notFound = {
  action() {
    BlazeLayout.render('App_body', { main: 'App_notFound' });
  },
};
