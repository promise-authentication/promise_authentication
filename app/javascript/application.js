// Entry point for the build script in your package.json
require("@rails/ujs").start()
require("turbolinks").start()
// require("@rails/activestorage").start()
// require("channels")

// import './css/markdown.scss'
// import './css/tailwind.css'
// import './css/input.scss'
// import './css/buttons.scss'
// import './css/globes.scss'
// import './css/animations.scss'

import LocalTime from "local-time"

LocalTime.config.i18n["da"] = {
  date: {
    dayNames: [
      "søndag",
      "mandag",
      "tirsdag",
      "onsdag",
      "torsdag",
      "fredag",
      "lørdag"
    ],
    abbrDayNames: [
      "søn",
      "man",
      "tir",
      "ons",
      "tor",
      "fre",
      "lør"
    ],
    monthNames: [
      "januar",
      "februar",
      "marts",
      "april",
      "maj",
      "juni",
      "juli",
      "august",
      "september",
      "oktober",
      "november",
      "december"
    ],
    abbrMonthNames: [
      "jan",
      "feb",
      "mar",
      "apr",
      "maj",
      "jun",
      "jul",
      "aug",
      "sep",
      "okt",
      "nov",
      "dec"
    ],
    yesterday: "i går",
    today: "i dag",
    tomorrow: "i morgen",
    on: "den {date}",
    formats: {
      default: "%d. %b %Y",
      thisYear: "%d. %b"
    }
  },
  time: {
    am: "",
    pm: "",
    singular: "{time}",
    singularAn: "{time}",
    elapsed: "for {time} siden",
    second: "sekund",
    seconds: "sekunder",
    minute: "minut",
    minutes: "minutter",
    hour: "time",
    hours: "timer",
    formats: {
      default: "%H:%M",
      default_24h: "%H:%M"
    }
  },
  datetime: {
    at: "{date} kl. {time}",
    formats: {
      default: "%d. %B %Y kl. %H:%M %Z",
      default_24h: "%d. %B %Y kl. %H:%M %Z"
    }
  }
}
LocalTime.start()
LocalTime.config.locale = navigator.language || navigator.userLanguage || "en";
