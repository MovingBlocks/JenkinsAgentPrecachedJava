## Pre-cached Jenkins Agent Docker Image

This is a simple example of a vanilla Jenkins agent extended to contain Gradle dependencies and wrapper-needed files for faster builds.

By cloning code and executing builds to a point we make Gradle fill its local cache directory ahead of time. Then we wipe actual cloned files to keep the image size smaller, before the rest is built into layers.

Realistically the Git workspaces could be kept and moved to a spot where Jenkins would look for them when building anew, meaning just recent commits would have to be pulled, but this is a minor convenience that could have quirks. Maybe later! Other improvements also possible.


### Setup in Jenkins

First be sure to create the included config map if not already present in the cluster in an appropriate namespace. It holds a copy of the Jenkins agent startup script.

Under a Kubernetes cloud add a new Pod Template with the following settings (and any others you would like to change):

* Container name: `jnlp`
* Docker image: `cervator/pre-cached-jenkins-agent`
* Working directory: `/home/jenkins/agent`
* Command to run: `/bin/sh`
* Arguments to pass to the command: `/var/jenkins_config/jenkins-agent`

This in short targets the startup script from the config map when Jenkins attempts to start its agent process on the container created with the image.

It _overrides_ the default `jnlp` container otherwise automatically created, to avoid having two containers (slight optimization). Any image used for a secondary container instead would have to run a command that simply won't exit (for the needed duration of the container, at least) so the container can be used after the `jnlp` container connects the agent to Jenkins. If the secondary container's command were to finish and exit it would no longer be "around" and accessible.


### Pre-caching more apps

At present simple hardwired blocks of Git clones & builds are included in the Dockerfile, one layer per block. Looping through a simple list of target Git repos would seem cleaner and go into a single layer.

One curiosity is whether the build would be smart enough to not update a layer if the associated application hasn't changed its dependencies? The code could differ but if nothing in the Gradle cache change then no-op. In which case one layer per app may still be preferable for image build/pull time?


### Docker Daemon

If only a single Gradle command is executed it _may_ be faster to disable the Gradle daemon. But if using multiple stages to run several Gradle commands then keeping the daemon around helps speed things up, even if the image is only ever used to do a single build.
