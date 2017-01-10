// All links-related publications

import { Meteor } from 'meteor/meteor';
import { Notes } from '../notes.js';

Meteor.publish('notes.all', function () {
  return Notes.find({ owner: this.userId });
});
