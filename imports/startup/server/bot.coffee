import { Random } from 'meteor/random'

import { Notes } from '/imports/api/notes/notes.coffee'

if Meteor.isServer
  Meteor.startup ->
    TelegramBot.token = Meteor.settings.telegramKey
    TelegramBot.maxTitleLength = 100
    TelegramBot.start()

    TelegramBot.formatNote = (note) ->
      title = note.title.replace(/(<([^>]+)>|:|_)/ig, " ")
      if title.length > TelegramBot.maxTitleLength
        title = title.substr(0,TelegramBot.maxTitleLength) + '...'
      title + ' - ' + Meteor.settings.public.url + '/note/' + note._id

    TelegramBot.setCatchAllText true, (_, message) ->
      user = Meteor.users.findOne({telegramId:message.chat.id.toString()})
      noteId = Meteor.call 'notes.inbox',
        userId: user._id
        title: message.text
        telegram: true
      TelegramBot.send 'Note Saved! ' + Meteor.settings.public.url + '/note/' + noteId, message.chat.id, true

    TelegramBot.addListener '/start', (command, username, data) ->
      user = Meteor.users.findOne({telegramId:data.chat.id.toString()})
      if !user
        'Hello '+ username + ', I am BulletNotesBot! I can help you save Notes quickly to BulletNotes.io.\n\nClick here to link your account: ' + Meteor.settings.public.url + '/telegramAuth/' + data.chat.id
      else
        'Your account is linked. Simply send me any note like `Walk the dog` to get started. Type `/help` for more commands.'

    TelegramBot.addListener '/help', (command) ->
      msg = 'I have the following commands available (more coming):\n'
      TelegramBot.triggers.text.forEach (post) ->
        msg = msg + '- ' + post.command + '\n'
      msg

    TelegramBot.addListener '/find', (command, _, data) ->
      # If a limit is not provided as the first param, use 10
      if command.length < 2
        'You must provide a search term.'
      else
        # Drop the /find from the command
        command.shift()
        user = Meteor.users.findOne({telegramId:data.chat.id.toString()})
        searchTerm = command.join(' ')
        notes = Notes.search searchTerm, user._id, 10

        msg = 'Here are your search results:\n'
        ii = 1
        notes.forEach (note) ->
          title = TelegramBot.formatNote note

          # Highlight search terms
          regex = new RegExp searchTerm, 'gi'
          title = title.replace regex, '*$&*'

          msg = msg + '*' + ii + '* - ' + title + '\n'
          ii++
        msg

    TelegramBot.addListener '/recent', (command, _, data) ->
      # If a limit is not provided as the first param, use 10
      limit = command[1] || 10
      # Cap the limit at 50
      limit = Math.min 50, limit
      user = Meteor.users.findOne({telegramId:data.chat.id.toString()})
      notes = Notes.find({owner:user._id,deleted:{$exists: false}},{sort:{createdAt:-1},limit:limit})

      msg = 'Here are your most recent '+limit+' notes:\n'
      ii = 1
      notes.forEach (note) ->
        msg = msg + '*' + ii + '* - ' + TelegramBot.formatNote(note) + '\n'
        ii++
      msg

    TelegramBot.addListener '/random', (command, _, data) ->
      # If a limit is not provided as the first param, use 10
      limit = command[1] || 10
      # Cap the limit at 50
      limit = Math.min 50, limit
      user = Meteor.users.findOne({telegramId:data.chat.id.toString()})
      notes = Notes.find({owner:user._id,deleted:{$exists: false}},{sort:{_id:Random.choice([1,-1])},limit:limit})

      msg = 'Here are '+limit+' random notes:\n'
      ii = 1
      notes.forEach (note) ->
        msg = msg + '*' + ii + '* - ' + TelegramBot.formatNote(note) + '\n'
        ii++
      msg

    TelegramBot.addListener '/delete', (command, username, data) ->
      # First find the most recent note the bot created
      user = Meteor.users.findOne({telegramId:data.chat.id.toString()})
      # We don't have a search param, grab the most recent note
      if command.length < 2
        note = Notes.findOne({owner:user._id,deleted:{$exists: false}},{sort:{createdAt:-1}})
      else
        command.shift()
        notes = Notes.search command.join(' '), user._id, 1
        notes.forEach (n) ->
          note = n

      # Start the conversation
      TelegramBot.startConversation username, data.chat.id, ((username, message, chat_id) ->
        obj = _.find(TelegramBot.conversations[chat_id], (obj) ->
          obj.username == username
        )
        if message.toLowerCase() == 'y' || message.toLowerCase() == 'yes'
          Notes.update obj.deleteId, $set:
            deleted: new Date()
          TelegramBot.send('Note deleted successfully.', chat_id);
        else
          TelegramBot.send('Delete note cancelled.', chat_id);
        TelegramBot.endConversation(username, chat_id);
      ),
        deleteId: note._id


      # The return in this listener will be the first prompt
      'The newest note is: `' + note.title + '`. Really delete it? (Y)es/(N)o'
