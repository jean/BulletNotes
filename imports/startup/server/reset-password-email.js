import { Accounts } from 'meteor/accounts-base';


Accounts.emailTemplates.siteName = 'BulletNotes.io';
Accounts.emailTemplates.from = 'BulletNotes <accounts@bulletnotes.io>';

Accounts.emailTemplates.resetPassword = {
  subject() {
    return 'Reset your password on BulletNotes.io';
  },
  text(user, url) {
    return `Hello!

Click the link below to reset your password on BulletNotes.

${url}

If you didn't request this email, please ignore it.

Thanks,
The BulletNotes.io team
`;
  },
//   html(user, url) {
//     return `
//       XXX Generating HTML emails that work across different email clients is a very complicated
//       business that we're not going to solve in this particular example app.
//
//       A good starting point for making an HTML email could be this responsive email boilerplate:
//       https://github.com/leemunroe/responsive-html-email-template
//
//       Note that not all email clients support CSS, so you might need to use a tool to inline
//       all of your CSS into style attributes on the individual elements.
// `
//   }
};
