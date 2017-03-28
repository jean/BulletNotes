import { Mongo } from 'meteor/mongo'
import { Factory } from 'meteor/dburles:factory'
import SimpleSchema from 'simpl-schema'
import faker from 'faker'

export Files = new Mongo.Collection 'files'

Files.deny
  insert: -> yes
  update: -> yes
  remove: -> yes

Files.schema = new SimpleSchema
  _id:
    type: String
    regEx: SimpleSchema.RegEx.Id
    optional: yes
  noteId:
    type: String
    regEx: SimpleSchema.RegEx.Id
  data:
    type: String
  name:
    type: String
  uploadedAt:
    type: Date
  owner:
    type: String
    regEx: SimpleSchema.RegEx.Id

Files.attachSchema Files.schema

Files.publicFields =
  noteId: 1
  data: 1
