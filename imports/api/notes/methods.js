// Methods related to links

import { Meteor } from 'meteor/meteor';
import { check } from 'meteor/check';
import { Notes } from './notes.js';

Meteor.methods({
  'notes.insert'(title) {
    check(title, String);

    var nextRank = Notes.find().count() + 1;


    return Notes.insert({
      title,
      createdAt: new Date(),
      rank: nextRank
    });
  },
  'notes.update'(id,title,rank) {
    check(title, String);
    check(rank, Number);

    return Notes.update(id,{ $set: {
      rank: rank,
      title: title
    }});
  },
  'notes.remove'(taskId) {
    check(taskId, String);
 
    Notes.remove(taskId);
  },
});
