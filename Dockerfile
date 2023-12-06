FROM centos:7

################################################################
# DEFINE sapcc and jvm version
################################################################
ARG SAPCC_VERSION=2.16.1
ARG SAPJVM_VERSION=8.1.096

################################################################
# Upgrade + install dependencies
################################################################
#RUN yum -y upgrade
#RUN yum -y update; yum clean all
RUN yum -y install which unzip wget net-tools less; yum clean all

################################################################
# Install dependencies and the SAP packages
################################################################

# HINT:
# In case automated download fails (see wget below) just download sapjvm + sapcc manually
# and put the downloaded files into a folder "sapdownloads" on the same level
# as this Dockerfile. Then pass them to the container by uncommenting the
# following command (then retry the next steps) + remove the 2 wget from RUN
# + adapt the zip filename and the 2 rpm filenames under RUN below:
#COPY sapdownloads /tmp/sapdownloads/

WORKDIR /tmp/sapdownloads

# download sapcc and sapjvm + unzip sapcc + install sapjvm and then install sapcc
# ATTENTION:
# This automated download automatically accepts SAP's End User License Agreement (EULA).
# Thus, when using this docker file as is you automatically accept SAP's EULA!
RUN wget --no-check-certificate --no-cookies --header "Cookie: eula_3_1_agreed=tools.hana.ondemand.com/developer-license-3_1.txt; path=/;" -S https://tools.hana.ondemand.com/additional/sapcc-$SAPCC_VERSION-linux-x64.zip && \
    wget --no-check-certificate --no-cookies --header "Cookie: eula_3_1_agreed=tools.hana.ondemand.com/developer-license-3_1.txt; path=/;" -S https://tools.hana.ondemand.com/additional/sapjvm-$SAPJVM_VERSION-linux-x64.rpm && \
    unzip sapcc-$SAPCC_VERSION-linux-x64.zip && \
    rpm -i sapjvm-$SAPJVM_VERSION-linux-x64.rpm && \
		rpm -i com.sap.scc-ui-${SAPCC_VERSION}*.x86_64.rpm

# set JAVA_HOME because this is needed by go.sh below, others are calulated
ENV JAVA_HOME=/opt/sapjvm_8/
#ENV CATALINA_BASE=/opt/sap/scc
#ENV CATALINA_HOME=/opt/sap/scc
#ENV CATALINA_TMPDIR=/opt/sap/scc/temp
#ENV SAPJVM_HOME=/opt/sapjvm_8/

#   let's just switch to bash (optional)
RUN chsh -s /bin/bash sccadmin

# Recommended: Replace the Default SSL Certificate ==> https://help.sap.com/viewer/cca91383641e40ffbe03bdc78f00f681/Cloud/en-US/bcd5e113c9164ae8a443325692cd5b12.html
## Use a Self-Signed Certificate ==> https://help.sap.com/viewer/cca91383641e40ffbe03bdc78f00f681/Cloud/en-US/57cb635955224bd58ac917a42bead117.html
#RUN export JAVA_EXE=/opt/sapjvm_8/bin/java
#RUN cd /opt/sap/scc/config
# get the currenct password
#RUN /opt/sapjvm_8/bin/java -cp /opt/sap/scc/plugins/com.sap.scc.rt*.jar -Djava.library.path=/opt/sap/scc/auditor com.sap.scc.jni.SecStoreAccess -path /opt/sap/scc/scc_config -p
# => current passwd [csW47YRjogt98IZy]
# TODO: use the retrieved password via CLI instead of having it hard coded here:
#RUN /opt/sapjvm_8/bin/keytool -delete -alias tomcat -keystore ks.store -storepass csW47YRjogt98IZy
#RUN /opt/sapjvm_8/bin/keytool -keysize 4096 -genkey -v -keyalg RSA -validity 3650 -alias tomcat -keypass csW47YRjogt98IZy -keystore ks.store -storepass csW47YRjogt98IZy -dname "CN=SCC, OU=YourCompany, O=YourCompany"

# expose connector server
EXPOSE 8443
USER sccadmin
WORKDIR /opt/sap/scc

# survive container destruction/recreation
VOLUME /opt/sap/scc/config
VOLUME /opt/sap/scc/scc_config
VOLUME /opt/sap/scc/log

# finally run sapcc as PID 1
CMD ./go.sh
