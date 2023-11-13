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
                        values "jdk8", "jdk11", "jdk17"
                    }
                }
                environment {
                    DOCKER_TAG = deduceDockerTag()
                }

                stages {
                    stage('Configure') {
                        steps {
                            container('kaniko') {
                                withCredentials([usernameColonPassword(credentialsId: 'docker-hub-terasology-token', variable: 'DOCKER_CRED')]) {
                                    writeFile(
                                        file: 'config.json',  // no permission to write to /kaniko directly
                                        text: readFile('config.tmpl.json').replaceAll(
                                            'PLACEHOLDER',
                                            DOCKER_CRED.bytes.encodeBase64().toString()
                                        )
                                    )
                                    sh 'mv config.json "${DOCKER_CONFIG}/config.json"'
                                }
                            }
                        }
                    }
                    stage('Build') {
                        steps {
                            container('kaniko') {
                                // Some troubleshooting trying to figure out if we got config.json right without
                                // revealing its secrets:
                                //     sh returnStatus: true, script: 'grep -c PLACEHOLDER ${DOCKER_CONFIG}config.json'
                                //     sh returnStatus: true, script: 'grep -c DOCKER_CRED ${DOCKER_CONFIG}config.json'
                                //     sh 'grep -c index.docker.io ${DOCKER_CONFIG}config.json'
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
