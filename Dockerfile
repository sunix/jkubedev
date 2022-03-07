FROM maven:3.8-eclipse-temurin-17
ARG JKUBE_MASTER_SHA=master
RUN echo reset to ${JKUBE_MASTER_SHA}
RUN apt-get -y update && \
    apt-cache search ack-grep && \
    apt-get -y install graphviz \
                       git git-svn git-email colordiff jq tig bash vim less openssh-client hub ack bash-completion wget unzip && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir /jkube
WORKDIR /jkube
RUN git clone https://github.com/eclipse/jkube . && \
    git reset --hard ${JKUBE_MASTER_SHA} && \
    (mvn install -Dmaven.test.skip -DskipTests || mvn install -Dmaven.test.skip -DskipTests) && \
    rm -rf /jkube;

WORKDIR /tmp
RUN curl https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz -s | tar zxv && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    install -o root -g root -m 0755 oc /usr/local/bin/oc && \
    rm kubectl && rm oc && rm README.md;
    

ENV HOME=/home/user
WORKDIR ${HOME}
ADD bashrc ${HOME}/.bashrc

RUN wget https://raw.github.com/git/git/master/contrib/completion/git-completion.bash && \
    wget https://raw.github.com/git/git/master/contrib/completion/git-prompt.sh

RUN mkdir /projects \
    # Store passwd/group as template files
    && cat /etc/passwd | sed s#root:x.*#root:x:\${USER_ID}:\${GROUP_ID}::\${HOME}:/bin/bash#g > ${HOME}/passwd.template \
    && cat /etc/group | sed s#root:x:0:#root:x:0:0,\${USER_ID}:#g > ${HOME}/group.template \
    # Change permissions to let any arbitrary user
    && for f in "${HOME}" "/etc/passwd" "/etc/group" "/projects" "/root"; do \
        echo "Changing permissions on ${f}" && chgrp -R 0 ${f} && \
        chmod -R g+rwX ${f}; \
    done

WORKDIR /projects

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD tail -f /dev/null

