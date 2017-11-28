import { Notes } from '/imports/api/notes/notes.coffee'

if Meteor.isServer
  Meteor.startup ->
    TelegramBot.token = Meteor.settings.telegramKey
    TelegramBot.start()

    TelegramBot.addListener '/note', (command, _, data) ->
      # command will contain the entire command in an array where command[0] is the command.
      # In this case '/note'. Each argument will follow.

      if command.length < 2
        'You must set a note for me to save. Something like: /note Walk the dog'

      else
        command.shift()
        user = Meteor.users.findOne({telegramId:data.chat.id.toString()})
        noteId = Meteor.call 'notes.inbox',
          userId: user._id
          title: command.join ' '

        'Note Saved! ' + Meteor.settings.public.url + '/note/' + noteId

    TelegramBot.addListener '/start', (command, username, data) ->
      user = Meteor.users.findOne({telegramId:data.chat.id.toString()})

      if !user
        'Hello '+ username + ', I am BulletNotesBot! I can help you save Notes quickly to BulletNotes.io.\n\nClick here to link your account: ' + Meteor.settings.public.url + '/telegramAuth/' + data.chat.id
      else
        'Your account is linked. Type `/note Walk the dog` or `/help` to get started.'

    TelegramBot.addListener '/help', (command) ->
      msg = 'I have the following commands available:\n'
      TelegramBot.triggers.text.forEach (post) ->
        msg = msg + '- ' + post.command + '\n'
        return
      msg
