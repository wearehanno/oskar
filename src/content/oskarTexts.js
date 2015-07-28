var OskarTexts;

String.prototype.format = function() {
  var args;
  args = arguments;
  return this.replace(/{(\d+)}/g, function(match, number) {
    if (typeof args[number] !== 'undefined') {
      return args[number];
    } else {
      return match;
    }
  });
};

OskarTexts = {
  statusText: {
    '1': 'pretty bad',
    '2': 'a bit down',
    '3': 'alright',
    '4': 'really good',
    '5': 'awesome'
  },
  introduction: "Hey {0}! Let me quickly introduce myself.\nMy name is Oskar, and the team has drafted me in to be their new happiness coach on Slack. I'm not going to bother you a lot, but every once in a while (usually twice a day), I'm gonna ask how you feel. Ready? *Just reply to this message and we'll give is a try* :smile:",
  firstMessage: "Alright! From now on, I'll check in once in a while to ask how you're feeling?'\n\nYou can reply to me with a number between 1 and 5, and I'll keep track of your answers over time and share them with your team.\n\nOK? Let's give it a try: *How do you feel right now?*\n (5) :heart_eyes_cat: Awesome\n (4) :smile: Really good\n (3) :neutral_face: Alright\n (2) :pensive: A bit down\n (1) :tired_face: Pretty bad\n",
  firstMessageSuccess: "That was easy, wasn't it? :smile: I'm gonna disappear for a few hours now, but I'll check in on you in a couple of hours, or tomorrow, if I miss you.",
  firstMessageFailure: "Whoops, it looks like you're trying to tell me how you feel, but unfortunately I only understand numbers between 1 and 5. Can you give it another go?",
  requestFeedback: {
    random: ["Hey {0}, How are you feeling right now? Hit me with a number and I'll share it with the rest of our team.\n", "Hello, me again! Just checking in to see how you're feeling. Want to share?\n", "Nice to see you, {0}, Wanna tell me how you feel? A number between 1 and 5 is all I need.\n"],
    selection: "(5) :heart_eyes_cat: Awesome\n (4) :smile: Really good\n (3) :neutral_face: Alright\n (2) :pensive: A bit down\n (1) :tired_face: Pretty bad\n",
    options: ["Perhaps you missed my last message... I'd really love to hear how you're doing. Would you mind letting me know?", "Hey, looks like you missed me last time, but if you can give me a number between 1-5 to let me know how you feel, I'll be on my way :smile:"]
  },
  faq: "Looks like you need a little help. Here's the link to the <http://oskar.herokuapp.com/faq|Oskar FAQ>",
  revealChannelStatus: {
    status: "*{0}* is feeling *{1}/5*",
    message: "\n>\"{0}\""
  },
  revealUserStatus: {
    error: "Oh, it looks like I haven\'t heard from {0} for a while. Sorry!",
    status: "*{0}* is feeling *{1}/5*",
    message: "\n>\"{0}\""
  },
  newUserFeedback: "*{0}* is feeling *{1}/5*\n>\"{2}\"",
  alreadySubmitted: ["Oops, looks like you've already told me how you feel in the last couple of hours. Let's check in again later.", "Oh, hey there! I actually have some feedback from you already, in the last 4 hours. Let's leave it a little longer before we catch up :smile:", "Easy, tiger! I know you love our number games, but let\'s wait a bit before we play again! I'll ping you in a few hours to see how you're doing."],
  invalidInput: ["Oh! I'm not sure what you meant, there: I only understand numbers between 1 and 5. Do you mind phrasing that a little differently?", "Oh! I'm not sure what you meant, there: I only understand numbers between 1 and 5. Do you mind phrasing that a little differently?", "I\'d really love to understand what you\'re saying, but until I become a little more educated, I'll need you to stick to using numbers between 1 and 5 to tell me how you feel."],
  lowFeedback: ["That sucks. I was really hoping you'd be feeling a little better than that. *Is there anything I should know?*", "Oh dear :worried: I'm having a rough day over here too... :tired_face: *Wanna tell me a little more?* Perhaps one of our teammates will be able to help out.", "Ah, man :disappointed: I really hate to hear when a friend is having a rough time. *Wanna explain a little more?* "],
  averageFeedback: ["Alright! Go get em :tiger: If you've got something you want to share, feel free. If not, have a grrreat day!", "Good luck with powering through things. if you've got something you want to share, feel free.", "That's alright. We can't all be having crazy highs and killer lows. Sometimes a little bit of normality is If you feel like telling me more, feel free!"],
  highFeedback: [":trophy: Winning! It's so great to hear that. Wanna tell me why things are going so well?", ":thumbsup: looks like you're on :fire: today. Is there anything you'd like to share with the team?", "There's nothing I like more than great feedback! :clap::skin-tone-4: What's made you feel so awesome today?"],
  feedbackReceived: ["Thanks a lot, buddy! Keep up the good work!", "You\'re a champion. Thanks for the input and have a great day!", "That\'s really helpful. I wish you good luck with everything today!"],
  feedbackMessageReceived: ["Thanks for sharing with me, my friend. Let's catch up again soon.", "Thanks for being so open! Let's catch up in a few hours.", "Gotcha. I've pinged that message to the rest of the team."]
};

module.exports = OskarTexts;
