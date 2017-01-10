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
      rank: nextRank,
      level: 0
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
  'notes.makeChild'(id,parent) {
    check(parent, String);
    var note = Notes.findOne(id);
    var parent = Notes.findOne(parent);
    if (!note || !parent) {
      return false;
    }
    var children = Notes.find({parent:note._id});
    // Set each child of the node being moved to the parent level, plus 2.
    children.forEach(function(child) {
      Notes.update(child.id,{$set:{level: parent.level+2}});
    });
    // Set the level to the parent level, plus 1. And set the parent.
    return Notes.update(id,{ $set: {
      parent: parent._id,
      level: parent.level+1
    }});
  },
  'notes.remove'(taskId) {
    check(taskId, String);
 
    Notes.remove(taskId);
  },
  'notes.outdent'(id) {
    var note = Notes.findOne(id);
    var parent = Notes.findOne(note.parent);
    parent = Notes.findOne(parent.parent);
    if (parent) {
      Meteor.call('notes.makeChild',note._id,parent._id);
    } else {
      return Notes.update(id,{ $set: {
        level: 0,
        parent: null
      }});
    }

  }
});
