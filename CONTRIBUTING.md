# Contributing to the Ansible Conjur Collection
Thanks for your interest in Conjur. Before contributing, please take a moment to
read and sign our <a href="https://github.com/cyberark/community/blob/master/documents/CyberArk_Open_Source_Contributor_Agreement.pdf" download="conjur_contributor_agreement">Contributor Agreement</a>.
This provides patent protection for all Conjur users and allows CyberArk to enforce
its license terms. Please email a signed copy to <a href="oss@cyberark.com">oss@cyberark.com</a>.
For general contribution and community guidelines, please see the [community repo](https://github.com/cyberark/community).

- [Contributing to the Ansible Conjur Collection](#contributing-to-the-ansible-conjur-collection)
  - [Prerequisites](#prerequisites)
  - [Set up a development environment](#set-up-a-development-environment)
      + [Setup a Conjur OSS Environment](#setup-a-conjur-oss-environment)
      + [Setup Conjur identity on managed host](#setup-conjur-identity-on-managed-host)
          - [Check Conjur identity](#check-conjur-identity)
          - [Set up Conjur identity](#set-up-conjur-identity)
          - [Set up Summon-Conjur](#set-up-summon-conjur)
      + [Troubleshooting](#troubleshooting)
   - [Testing](#testing)
   - [Releasing](#releasing)


 ## Prerequisites

To start developing and testing using our development scripts ,
the following tools need to be installed:

1. [Git][get-git] to manage source code
2. [Docker][get-docker] to manage dependencies and runtime environments
3. [Docker Compose][get-docker-compose] to orchestrate Docker environments

[get-docker]: https://docs.docker.com/engine/installation
[get-docker-compose]: https://docs.docker.com/compose/install
[get-git]: https://git-scm.com/downloads

# Set up a development environment

The `dev` directory contains a `docker-compose` file which creates a development
environment : 
-  A Conjur Open Source instance
-  An Ansible control node
-  Managed nodes to push tasks to

To use it:

1. Install dependencies (as above)

1. To setup the dev environment ,first need to Clone GitHub [conjur-collection-quickstart](https://github.com/cyberark/ansible-conjur-collection) repository in your directory and then run start.sh script 
    

 ```sh-session
 $ git clone https://github.com/cyberark/ansible-conjur-collection.git
 $ cd dev
 $ ./start.sh

 ```
### Verification

  When start.sh script successfully setup Conjur environment along with inventory machines , the terminal returns the following:
        
   ```sh-session
   ...
   PLAY RECAP *********************************************************************
   ansibleplugingtestingconjurhostidentity-test_app_centos-1 : ok=17 ...
   ansibleplugingtestingconjurhostidentity-test_app_centos-2 : ok=17 ...
   ansibleplugingtestingconjurhostidentity-test_app_ubuntu-1 : ok=16 ...
   ansibleplugingtestingconjurhostidentity-test_app_ubuntu-2 : ok=16 ...
   
   ```

   After starting Conjur, your instance will be configured with the following:
   * Account: `cucumber`
   * User: `admin`
   * Password: Run `conjurctl role retrieve-key cucumber:user:admin` inside the Conjur container shell to retrieve the admin user API key (which is also the  password)

## Setup a Conjur OSS Environment

- Build, create, and start containers for OSS Conjur service
- Use .j2 template to generate inventory prepended with COMPOSE_PROJECT_NAME
- Deploy Conjur Lookup Plugin for Ansible
- Prepare and run Conjur Policy as [root.yml](#conjur-policy-example)
  ```sh
   docker exec conjur_client conjur policy load root /policy/root.yml
  ```
- Centralise the secrets

## Setup Conjur identity on managed host

### Check Conjur identity

- Set variable "Conjurized", if /etc/Conjur.identity already exists
- Ensure all required variables are set-
    - Conjur_account
    - Conjur_appliance_url
    - Conjur_host_name
- Set variable "ssl_configuration"
- Ensure all required ssl variables are set-
    - Conjur_ssl_certificate
    - Conjur_validate_certs
 - Set variable "ssl file path" at a path like "/etc/Conjur.pem"
 - Set variable when non ssl configuration
    - Conjur_ssl_certificate_path: ""
    - Conjur_validate_certs: no
- Ensure "Conjur_host_factory_token" is set (if node is not already Conjurized)

### Set up Conjur identity

- Install "ca-certificates" ,in case of any issue it retries 10 times on every 2 seconds of delay
- Place Conjur public SSL certificate
- Symlink Conjur public SSL certificate into /etc/ssl/certs
- Install openssl-perl Package when ansible_os_family is 'RedHat', in case of any issue it retries 10 times on every 2 seconds of delay
- copy files from the Ansible to the hosts  into /etc/Conjur.conf
- Request identity from Conjur
- Place identity file /etc/Conjur.identity when not Conjurized .

### Set up Summon-Conjur

- Download and unpack Summon
- Create folder for Summon-Conjur to be installed into
- Download and unpack Summon-Conjur

### Conjur Policy example

```sh
- !policy
  id: ansible
  annotations:
    description: Policy for Ansible master and remote hosts
  body:

  - !host
    id: ansible-master
    annotations:
      description: Host for running Ansible on remote targets

  - !layer &remote_hosts_layer
    id: remote_hosts
    annotations:
      description: Layer for Ansible remote hosts

  - !host-factory
    id: ansible-factory
    annotations:
      description: Factory to create new hosts for ansible
    layer: [ *remote_hosts_layer ]

  - !variable
    id: target-password
    annotations:
      description: Password needed by the Ansible remote machine

  - !permit
    role: *remote_hosts_layer
    privileges: [ execute ]
    resources: [ !variable target-password ]
```

## Troubleshooting

### `Failed to open TCP connection` error for Conjur login

If you are
[using persistent Conjur configuration](#using-persistent-conjur-configuration),
and you see the following error when trying to log into Conjur:

```
error: Failed to open TCP connection to conjur:80 (Connection refused - connect(2) for "conjur" port 80)
```

Then try the following:

1. Run the following command:

   ```
   docker-compose logs conjur | grep "already running"
   ```

1. If the command in Step 1 produces the following line:

   ```
   A server is already running. Check /opt/conjur-server/tmp/pids/server.pid.
   ```

   then it may be that the Conjur container was stopped (e.g.
   `docker-compose stop conjur`) and restarted
   (`docker-compose up -d conjur`)
   without being brought fully down (e.g. with `docker-compose down conjur`),
   leaving the container with stale connection state.

   To recover from this, run:

   ```
   docker-compose down conjur
   docker-compose up -d conjur
   ```

   And log in again, e.g.:

   ```
   docker-compose exec client conjur authn login -u admin
   ```

1. If "A server is already running" does not show in the Conjur container
   logs, or Step 2 above is unsuccessful, then try restarting all containers:

   ```
   docker-compose down
   docker-compose up -d
   ```

   and try logging in again, e.g.:

   ```
   docker-compose exec client conjur authn login -u admin
   ```

### Useful links

- [Official documentation for Conjur's Ansible integration](https://docs.conjur.org/Latest/en/Content/Integrations/ansible.html)
- [Conjur Collection on Ansible Galaxy](https://galaxy.ansible.com/cyberark/conjur)
- [Ansible documentation for the Conjur collection](https://docs.ansible.com/ansible/latest/collections/cyberark/conjur/index.html)

## Testing

To run a specific set of tests:

```sh-session
$ cd tests
$ ./test.sh -d <role or plugin name>
```
To run all tests:

```sh-session
$ cd tests
$ ./test.sh -a
```

## Releasing

From a clean instance of main, perform the following actions to release a new version
of this plugin:

- Update the version number in [`galaxy.yml`](galaxy.yml) and [`CHANGELOG.md`](CHANGELOG.md)
    - Verify that all changes for this version in `CHANGELOG.md` are clear and accurate,
      and are followed by a link to their respective issue
    - Create a PR with these changes

- Create an annotated tag with the new version, formatted as `v##.##.##`
    - This will kick off an automated script which publish the release to
      [Ansible Galaxy](https://galaxy.ansible.com/cyberark/conjur)

- Create the release on GitHub for that tag
    - Build the release package with `./ci/build_release`
    - Attach package to Github Release

