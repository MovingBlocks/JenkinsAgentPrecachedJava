FROM jenkins/agent

MAINTAINER cervator@gmail.com

# Prep some basics - make dirs and disable the Gradle daemon (one-time build agents gain nothing from the daemon)
RUN mkdir -p ~/.gradle \
    # && echo "org.gradle.daemon=false" >> ~/.gradle/gradle.properties \ # ... unless you have a multi-phase build
    && mkdir ~/ws

# Now grab some source code and run a minimal Gradle build to force fetching of wrappers and any immediate dependencies
RUN cd ~/ws \
    && git clone https://github.com/MovingBlocks/joml-ext.git \
    && cd joml-ext \
    &&  ./gradlew compileJava \
    && rm -rf ~/ws/joml-ext

# This step builds the Terasology engine. As a special step it prepares a "build harness" to build modules standalone
RUN cd ~/ws \
    && git clone https://github.com/MovingBlocks/Terasology.git \
    && cd Terasology \
    &&  ./gradlew extractNatives extractConfig compileJava \
    && mkdir -p ~/ws/harness &&  mkdir -p ~/ws/harness/build-logic/src \
        && cp gradlew ~/ws/harness \
        && cp -r gradle ~/ws/harness/gradle \
        && cp templates/build.gradle ~/ws/harness \
        && cp -r config ~/ws/harness \
        && cp -r natives ~/ws/harness \
        && cp -r build-logic/src ~/ws/harness/build-logic \
        && cp build-logic/*.kts ~/ws/harness/build-logic \
        # This last bit is special and quirky - TODO improve the Terasology module build harness to avoid this
        && echo 'includeBuild("build-logic")' >>  ~/ws/harness/settings.gradle \
    && rm -rf ~/ws/Terasology

RUN cd ~/ws \
    && git clone https://github.com/Terasology/Sample.git \
    && cd Sample \
    && cp -r ~/ws/harness/* . \
    && ./gradlew compileJava \
    && rm -rf ~/ws/Sample
