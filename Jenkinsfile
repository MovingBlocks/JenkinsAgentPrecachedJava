String deduceDockerTag() {
    String dockerTag = env.BRANCH_NAME
    if (dockerTag.equals("main")) {
        echo "Building the 'main' branch so we'll publish a Docker tag starting with 'latest'"
        dockerTag = "latest"
    } else {
        dockerTag += env.BUILD_NUMBER
        echo "Building a branch other than 'main' so will publish a Docker tag starting with '$dockerTag', not 'latest'"
    }
    return dockerTag
}

pipeline {
    agent none

    stages {
        stage('Versions') {
            matrix {
                agent {
                    label 'kaniko'
                }
                axes {
                    axis {
                        name "JDKVERSION"
                        values "jdk8", "jdk11"
                    }
                }
                environment {
                    DOCKER_CRED = credentials('docker-hub-terasology-token')
                    DOCKER_TAG = deduceDockerTag()
                }

                stages {
                    stage('Configure') {
                        steps {
                            container('kaniko') {
                                sh '''
                                    set +x
                                    tokenVar=$(echo -n $DOCKER_CRED | base64) > out.log 2>&1
                                    sed -i "s/PLACEHOLDER/$tokenVar/g" config.json > out.log 2>&1
                                    set -x
                                    cp config.json /kaniko/.docker/config.json
                                '''
                            }
                        }
                    }
                    stage('Build') {
                        steps {
                            container('kaniko') {
                                sh '''
                                    /kaniko/executor -f ./Dockerfile -c $(pwd) --reproducible \\
                                        --destination=terasology/jenkins-precached-agent:$DOCKER_TAG-$JDKVERSION \\
                                        --build-arg JDKVERSION=$JDKVERSION
                                '''
                            }
                        }
                    }
                }
            }
        }
    }
}
