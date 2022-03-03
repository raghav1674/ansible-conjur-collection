# Contributing to the Ansible Conjur Collection
Thanks for your interest in Conjur Collection . Before contributing, please take a moment to
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
   - [Testing](#testing)
   - [Releasing](#releasing)


 ## Prerequisites

To start developing and testing using our development scripts ,
the following tools need to be installed:

1. [Git][get-git] to manage source code
2. [Docker][get-docker] to manage dependencies and runtime environments
3. [Docker Compose][get-docker-compose] to orchestrate Docker environments
4. [Ruby][install-ruby] - native installation 
5. [Python][Python] - for lookup plug-in


[get-docker]: https://docs.docker.com/engine/installation
[get-docker-compose]: https://docs.docker.com/compose/install
[get-git]: https://git-scm.com/downloads
[install-ruby]: https://www.ruby-lang.org/en/documentation/installation/
[Python]: https://packaging.python.org/en/latest/tutorials/installing-packages/


## Set up a development environment

For developers, it is easy-to-use development environment, so that they can work on the collection, roles, plugins, and playbooks without needing to run the test suite. The repo scripts is in dev/ to setup and teardown this environment.
This docker-compose dev environment is really useful, including a few different services:
-  A Conjur Open Source instance
-  An Ansible control node
-  Managed nodes to push tasks to

The `dev` directory contains a `docker-compose` file which creates a development
environment with a database container (`pg`, short for *postgres*), and a
`conjur` server container with source code mounted into the directory
`/cyberark/dev/`.

To use it:

1. Install dependencies (as above)

1. Start the container (and optional extensions):

   ```sh-session
   $ cd dev
   $ ./start.sh
   ...
   root@f75015718049:/cyberark/dev/#
   ```

   Once the `start` script finishes, you're in a Bash shell inside the Conjur
   server container.  To

   After starting Conjur, your instance will be configured with the following:
   * Account: `cucumber`
   * User: `admin`
   * Password: Run `cat conjur.identity` inside the container shell to display the current logged-in identity (which is also the password)

1. Debug the server

   ```sh-session
   root@f39015718062:docker-compose exec <container-service-name> bash
   <various startup messages, then finally:>
   Use exit to stop
   ```

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

- [Check Conjur identity](#check-conjur-identity)
- [Set up Conjur identity](#set-up-conjur-identity)
- [Set up Summon-Conjur](#set-up-summon-conjur)

## Check Conjur identity

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

## Set up Conjur identity

- Install "ca-certificates" ,in case of any issue it retries 10 times on every 2 seconds of delay
- Place Conjur public SSL certificate
- Symlink Conjur public SSL certificate into /etc/ssl/certs
- Install openssl-perl Package when ansible_os_family is 'RedHat', in case of any issue it retries 10 times on every 2 seconds of delay
- copy files from the Ansible to the hosts  into /etc/Conjur.conf
- Request identity from Conjur
- Place identity file /etc/Conjur.identity when not Conjurized .

## Set up Summon-Conjur

- Download and unpack Summon
- Create folder for Summon-Conjur to be installed into
- Download and unpack Summon-Conjur

## Conjur Policy example

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

## Useful links

| Source  | URLs |
| ------ | ------ |
| CyberArk Conjur |https://docs.conjur.org/Latest/en/Content/Integrations/ansible.html|
| GitHub | https://github.com/cyberark/ansible-conjur-collection|
| Ansible Galaxy | https://galaxy.ansible.com/cyberark/conjur_collection|
| Ansible Doc| https://docs.ansible.com/ansible/latest/collections/cyberark/conjur/index.html|


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

