discourse-user-publications/
├── plugin.rb
├── config/
│   ├── settings.yml
│   └── locales/
│       ├── server.en.yml
│       └── client.en.yml
├── db/
│   └── migrate/
│       └── 20260330000000_create_user_publications.rb
├── app/
│   ├── models/
│   │   └── user_publication.rb
│   ├── controllers/
│   │   └── discourse_user_publications/
│   │       └── publications_controller.rb
│   └── jobs/
│       └── regular/
│           └── sync_orcid_publications.rb
├── assets/
│   └── javascripts/
│       └── discourse/
│           ├── initializers/
│           │   └── setup-user-publications.js
│           ├── routes/
│           │   └── user-publications.js
│           ├── components/
│           │   ├── user-publications-list.gjs
│           │   └── modal/
│           │       └── edit-publication.gjs
└── config/
    └── routes.rb