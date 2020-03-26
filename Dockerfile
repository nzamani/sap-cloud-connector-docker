FROM centos:7

################################################################
# General information
################################################################
LABEL com.nabisoft.sapcc.version="2.12.0.1"
LABEL com.nabisoft.sapcc.sapjvm.version="8.1.055"
LABEL com.nabisoft.sapcc.vendor="Nabi Zamani"
LABEL com.nabisoft.sapcc.name="SAP Cloud Connector"

################################################################
# Upgrade + install dependencies
################################################################
#RUN yum -y upgrade
RUN yum -y install initscripts which unzip wget net-tools less

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
RUN wget --no-check-certificate --no-cookies --header "Cookie: eula_3_1_agreed=tools.hana.ondemand.com/developer-license-3_1.txt; path=/;" -S https://tools.hana.ondemand.com/additional/sapcc-2.12.3-linux-x64.zip && \
    wget --no-check-certificate --no-cookies --header "Cookie: eula_3_1_agreed=tools.hana.ondemand.com/developer-license-3_1.txt; path=/;" -S https://tools.hana.ondemand.com/additional/sapjvm-8.1.062-linux-x64.rpm && \
    unzip sapcc-2.12.3-linux-x64.zip && \
    rpm -i sapjvm-8.1.062-linux-x64.rpm && \
	rpm -i com.sap.scc-ui-2.12.3-8.x86_64.rpm

# You could also use Oracle JDK (feel free to skip JCE download + installation)
#RUN wget --no-check-certificate --no-cookies --header "Cookie: gpw_e24=http%3a%2F%2Fwww.oracle.com%2Ftechnetwork%2Fjava%2Fjavase%2Fdownloads%2Fjdk8-downloads-2133151.html; oraclelicense=accept-securebackup-cookie;" -S "https://download.oracle.com/otn-pub/java/jdk/8u202-b08/1961070e4c9b4e26a04e7f5a083f551e/jdk-8u202-linux-x64.rpm" && \
#    wget --no-check-certificate --no-cookies --header "Cookie: gpw_e24=http%3a%2F%2Fwww.oracle.com%2Ftechnetwork%2Fjava%2Fjavase%2Fdownloads%2Fjdk8-downloads-2133151.html; oraclelicense=accept-securebackup-cookie;" -S "http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip" && \
#    rpm -i jdk-8u202-linux-x64.rpm && \
#    unzip jce_policy-8.zip && rm jce_policy-8.zip && cp -v UnlimitedJCEPolicyJDK8/*.jar /usr/java/default/jre/lib/security/ && \
#    wget --no-check-certificate --no-cookies --header "Cookie: eula_3_1_agreed=tools.hana.ondemand.com/developer-license-3_1.txt; path=/;" -S https://tools.hana.ondemand.com/additional/sapcc-2.12.1.1-linux-x64.zip && \
#    unzip sapcc-2.12.1.1-linux-x64.zip && rpm -i com.sap.scc-ui-2.12.1-5.x86_64.rpm


# HINT:
# In case the downloads fail you might have to update the wget urls.
# In such cases please also let me know by opening an issue so that I can update this dockerfile.

# Docker is based on PID 1, but service is already started bacause of rpm installation.
# Furthermore, we don't want to run the container in a "--privileged" container.
# Solution: Stop service + start the java process manually (see CMD below).
# Hint: changing the shell to bash via chsh is optional.
#RUN service scc_daemon stop && chsh -s /bin/bash sccadmin
### this is not needed anymore because auto start via rpm fails anyway, so no need to stop
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

# finally run sapcc as PID 1

# For Oracle JDK use this command:
#CMD /usr/bin/java \
# SAP JVM
CMD /opt/sapjvm_8/bin/java \
	-server \
	-XtraceFile=log/vm_@PID_trace.log \
	-XX:+GCHistory \
	-XX:GCHistoryFilename=log/vm_@PID_gc.prf \
	-XX:+HeapDumpOnOutOfMemoryError \
	-XX:+DisableExplicitGC \
	-Xms1024m \
	-Xmx1024m \
	-XX:MaxNewSize=512m \
	-XX:NewSize=512m \
	-XX:+UseConcMarkSweepGC \
	-XX:TargetSurvivorRatio=85 \
	-XX:SurvivorRatio=6 \
	-XX:MaxDirectMemorySize=2G \
	-Dorg.apache.tomcat.util.digester.PROPERTY_SOURCE=com.sap.scc.tomcat.utils.PropertyDigester \
	-Dosgi.requiredJavaVersion=1.6 \
	-Dosgi.install.area=. \
	-DuseNaming=osgi \
	-Dorg.eclipse.equinox.simpleconfigurator.exclusiveInstallation=false \
	-Dcom.sap.core.process=ljs_node \
	-Declipse.ignoreApp=true \
	-Dosgi.noShutdown=true \
	-Dosgi.framework.activeThreadType=normal \
	-Dosgi.embedded.cleanupOnSave=true \
	-Dosgi.usesLimit=30 \
	-Djava.awt.headless=true \
	-Dio.netty.recycler.maxCapacity.default=256 \
	-jar plugins/org.eclipse.equinox.launcher_1.1.0.v20100507.jar

#	-Xdebug \
#	-Xrunjdwp:transport=dt_socket,address=8000,server=y,suspend=n \
#	-console

#CMD ["/opt/sapjvm_8/bin/java","-server","-XtraceFile=log/vm_@PID_trace.log","-XX:+GCHistory","-XX:GCHistoryFilename=log/vm_@PID_gc.prf","-XX:+HeapDumpOnOutOfMemoryError","-XX:+DisableExplicitGC","-Xms1024m","-Xmx1024m","-XX:MaxNewSize=512m","-XX:NewSize=512m","-XX:+UseConcMarkSweepGC","-XX:TargetSurvivorRatio=85","-XX:SurvivorRatio=6","-XX:MaxDirectMemorySize=2G","-Dorg.apache.tomcat.util.digester.PROPERTY_SOURCE=com.sap.scc.tomcat.utils.PropertyDigester","-Dosgi.requiredJavaVersion=1.6","-Dosgi.install.area=.","-DuseNaming=osgi","-Dorg.eclipse.equinox.simpleconfigurator.exclusiveInstallation=false","-Dcom.sap.core.process=ljs_node","-Declipse.ignoreApp=true","-Dosgi.noShutdown=true","-Dosgi.framework.activeThreadType=normal","-Dosgi.embedded.cleanupOnSave=true","-Dosgi.usesLimit=30","-Djava.awt.headless=true","-Dio.netty.recycler.maxCapacity.default=256","-jar plugins/org.eclipse.equinox.launcher_1.1.0.v20100507.jar"]

#HINT:
# The CMD above is basically derived from the SAPCC "portable" archives which can be
# downloaded from https://tools.hana.ondemand.com/#cloud, i.e. sapcc-2.12.0.1-windows-x64.zip, sapcc-2.12.0.1-linux-x64.tar.gz, sapcc-2.12.0.1-macosx-x64.tar.gz
# To verify this, simply extract any of these archives and check the files "deamon.sh" and "props.ini".
# The first 4 option in CMD are derived from deamon.sh, all other options are derived from the props.ini file.
