## What is this?
This repo has the docker code to:
 - build a docker image for inaturalist (the Ruby app)
 - build a docker image for the inaturalist API (the NodeJS app)
 - run a docker-compose stack including all the other parts of the system:
     postgres, elasticsearch, etc

We developed this so we can easily spin up a dev environment for development of
an app that communicates with iNat.

**This is not production ready**. It's not even complete. It works as a simple
dev server but there is still a lot more of the configuration that needs to be
configurable via env vars. Basically, it's done to the point that it served our
purposes.

Think carefully before using this to run your own production instance of inat.
Quote taken from [the inat developers
page](https://www.inaturalist.org/pages/developers):
> If you're considering forking our web app code in order to build a narrower
> version of iNat, please talk to us first! While we welcome forks to the
> software, we don't want to fork our community. Social networks lose their value
> when they fragment, so if you're thinking of making "iNat for Country X" or
> "iNat for Lepidopterists" or something, let's discuss ways that we can
> incorporate your needs into our existing infrastructure. We have a mechanism for
> localization through our international iNaturalist Network.

## Getting started with this repo

This repo uses git submodules. The docker related code is stored in this repo
but then we have the inat and API codebases as submodules so we can pin the
commit and make building easy.

Here's how you clone the repo:
```bash
git clone ...
git submodule init # gets the submodules ready
git submodule update # clones the submodules and checks out the right commit
```

Then in the future, whenever you do a `git pull`, keep an eye out for updates to
the submodules and run a `git submoduel update` (FIXME or maybe a `git submodule
sync`?). If you're unsure, just run it. It's idempotent.


## Quickstart getting a stack running
  1. get yourself a host machine
  1. install Docker (tested with version 18.09.7, build 2d0083d)
  1. install docker-compose (tested with version 1.23.2, build 1110ad01)
  1. clone this repo onto the host
  1. `cp start-or-restart-stack.sh.example start-or-restart-stack.sh`
  1. `vim start-or-restart-stack.sh` to add all the values it asks for
  1. `chmod +x start-or-restart-stack.sh`
  1. for the first time **only** after cloning `git submodule init`
  1. everytime, make sure the submodule are up to date `git submodule update`
  1. start the stack `./start-or-restart-stack.sh`
  1. watch the logs `docker logs -f inat_app` until Rails has started
  1. if you need to run the "only on first run" tasks, you can do it with:
      ```bash
      docker exec -it inat_app bash
      bash /srv/inat/docker/optional-first-run-items.sh
      # or for the impatient, you'll be able to create a user after running
      # rake es:rebuild
      ```
  1. point your browser to the URL you configured (both in the
     `start-or-restart-stack.sh` file and in your DNS) for the iNat service
  1. sign up as a new user
  1. optional, make yourself an admin:
        1. go back to your terminal on the docker host
              ```bash
              ./scripts/db-psql.sh
              ```
        1. run this SQL
              ```sql
              insert into roles_users values (1,1); -- assumes your user ID = 1
              ```
        1. you can now visit <*inat.hostname*>/admin in your browser
        1. as an admin, you can also bypass the rules for a minimum number of
             observations before you can do certain things like create a traditional
             project <*inat.hostname*>/projects/new_traditional

## Avoiding cached docker images
Running the start script with `--build` still relies on a cache of docker images
to speed up rebuilds. If you see anything that looks like stale files in your
docker builds, you can cache bust by running `docker-compose build --no-cache`.

## Connecting to Postgres
The container doesn't expose a post so you can't connect to it from outside but
you can `exec` into it and run `psql`. There is a script that will drop you
into a `psql` shell inside the docker container:

```bash
./scripts/db-psql.sh
```

## Performing a database dump
We have a script that will perform this for you:
```bash
# note, the output path is on the docker *host*, not inside the container
./scripts/db-dump.sh /tmp/inat-pg.backup
```

## Performing a database restore
We have a script that will perform this for you:
```bash
# note, the input path is on the docker *host*, not inside the container
./scripts/db-restore.sh /tmp/inat-pg.backup
```

If you didn't want to connect to this DB, then you can use `\l` to list
the available databases and connect to them with `\c <database name>`.

## Debugging Ruby inside the Docker container

  1. edit the `docker-compose.yml` file to override the entrypoint for
     `inat_app`. We need our terminal to be attached to the shell that runs
     rails so we'll set a noop entrypoint:
      ```yml
      services:
        inat:
          ...existing stuff...
          entrypoint: sh -c 'sleep 9999999999' # add this line
      ```
  1. (re)start the docker stack:
      ```bash
      ./start-or-restart-stack.sh
      ```
  1. exec into the docker container:
      ```bash
      docker exec -it inat_app bash
      ```
  1. (optional) install a text editor:
      ```bash
      apt-get update && apt-get -y install --no-install-recommends vim
      ```
  1. edit any file (using vim) you want to add a breakpoint to and simply add a
     line with `debugger`. You can debug the iNat code but you can also debug
     gems. See where they live with `gem env` and the output will have
     `INSTALLATION DIRECTORY: /usr/local/bundle`. You can edit any file in
     `/usr/local/bundle/gems/` to add a debugger statement.
  1. start the server
      ```bash
      bash docker/entrypoint.sh
      ```
  1. interact with the server to trigger the breakpoint, then jump back to your
     terminal and you'll see the debugger waiting with a `(byebug)` prompt. The
     `h` command will print debugging help
  1. apparently [pry](http://pryrepl.org/) is an enhanced debugger that you
     could look at using too

## Performing the OAuth workflow by hand
Sometimes you want to get a token, so here's how.

These scripts use [httpie](https://httpie.org/), so make sure you have it
installed.

### Authorization code flow with PKCE

  1. go to the /oauth/applications/{id} page in your iNat instance
  1. click the *Authorize with PKCE* link
  1. copy the `code` from the redirected URL, it doesn't matter if there's no
     listening server
  1.  Create a bash script with the following:
      ```bash
      # TODO YOU need to update all these values
      inatServerDomain='https://your.inat.instance' # the URL of your iNat instance (use HTTPS if needed)
      # get these from the /oauth/applications/<id> page in iNat
      clientId='REPLACE-ME-ed4be74c44dccb8efdc1e8cf0d408c50e7f6d88bfb3e0e3839825'
      redirectUri='http://localhost:8080/oauth-callback'
      # this should be the matching code_verifier from the link that the UI generates
      codeVerifier='some_terrible_challenge'
      # replace with the code you copied above
      code='REPLACE-ME-e91fa6a6e3d1854e1b508ae82f8147ff180e5a51199ed074920a6'

      http -v \
       $inatServerDomain/oauth/token \
       client_id=$clientId \
       redirect_uri=$redirectUri \
       code=$code \
       grant_type=authorization_code \
       code_verifier=$codeVerifier
      ```
  1. save and run the script
  1. the response will contain your token (the `access_token` field), it will look something like:
      ```json
      {
        "access_token": "5ca26e9aaaaaa6fa0116c13869ad8fd7a8e118d32b6a0a2aed37f4301cb32029",
        "created_at": 1581041101,
        "scope": "write login",
        "token_type": "Bearer"
      }
      ```

### Exchange an iNat token for an iNat API JWT
The iNat (Ruby on Rails) server uses a different authentication mechanism from
the iNat API (built with NodeJS). Now you have the token from the iNat server
(step above) you can use that to get a JWT that can be used for the iNat API.

  1. run the following (note: we still use some env vars from)
      ```bash
      # TODO YOU need to update all these values
      inatServerDomain='https://your.inat.instance' # the URL of your iNat instance (use HTTPS if needed)
      inatToken='access_token-from-steps-above'

      http -v $inatServerDomain/users/api_token \
        Authorization:"Bearer $inatToken"
      ```
  1. the response will be your JWT, something like:
      ```json
      {
        "api_token": "eyJhbGciOiJIUzUxMiJ9.eyJ1c2VyX2lkIjoxLCJvYXV0aaaaaaasaWNhdGlvbl9pZCI6MiwiZXhwIjoxNTgxMTI3MDc4fQ.Ti4aSGEylor-p60MyQCyUAV2I6SO-nEYzmyVeo3sQ1gTNK0HNdQhieU4zqJpyABYtb_C8sjytA8fwFMG4KhTSQ"
      }
      ```
