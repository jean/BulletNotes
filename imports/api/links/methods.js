// Methods related to links

import { Meteor } from 'meteor/meteor';
import { check } from 'meteor/check';
import { Links } from './links.js';

Meteor.methods({
  'links.insert'(title) {
    check(title, String);

    return Links.insert({
      title,
      createdAt: new Date(),
    });
  },
  'links.remove'(taskId) {
    check(taskId, String);
 
    Links.remove(taskId);
  },
});
