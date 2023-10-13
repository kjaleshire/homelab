# Azerothcore Custom CI configuration

This directory holds the Gitlab CI configuration which can 1) mirror the Azerothcore repository and 2) build production images from scratch.

To use, fork Azerothcore master, copy in this config, commit and push to Gitlab.

The mirror job must be scheduled (overnight job) on the Gitlab project CI settings. These environment variables must be set:

`GITLAB_HOST`: Gitlab domain, sans protocol & path
`GITLAB_SSH_PORT`: self-explanatory
`GIT_USER_EMAIL`: Gitlab user email
`GIT_USER_NAME`: Gitlab username
`SSH_PRIVATE_KEY`: Gitlab user's SSH key that can push to the mirror repo

To build new images, just run the pipeline. A Github token must be generated with repo write privileges in order to push packages and set in `GITHUB_TOKEN`.
