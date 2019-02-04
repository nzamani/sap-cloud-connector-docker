FROM centos:7

################################################################
# General information
################################################################
LABEL com.nabisoft.sapcc.version="2.11.3"
LABEL com.nabisoft.sapcc.sapjvm.version="8.1.048"
LABEL com.nabisoft.sapcc.vendor="Nabi Zamani"
LABEL com.nabisoft.sapcc.name="SAP Cloud Connector"

################################################################
# Upgrade + install dependencies
################################################################
#RUN yum -y upgrade
RUN yum -y install initscripts which unzip wget net-tools

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
RUN wget --no-check-certificate --no-cookies --header "Cookie: eula_3_1_agreed=tools.hana.ondemand.com/developer-license-3_1.txt; path=/;" -S https://tools.hana.ondemand.com/additional/sapcc-2.11.3-linux-x64.zip && \
    wget --no-check-certificate --no-cookies --header "Cookie: eula_3_1_agreed=tools.hana.ondemand.com/developer-license-3_1.txt; path=/;" -S https://tools.hana.ondemand.com/additional/sapjvm-8.1.048-linux-x64.rpm && \
    unzip sapcc-2.11.3-linux-x64.zip && \
    rpm -i sapjvm-8.1.048-linux-x64.rpm && rpm -i com.sap.scc-ui-2.11.3-6.x86_64.rpm

# HINT:
# In case the downloads fail you might have to update the wget urls.
# In such cases please also let me know by opening an issue so that I can update this dockerfile.

# Docker is based on PID 1, but service is already started bacause of rpm installation.
# Furthermore, we donät want to run the container in a "--privileged" container.
# Solution: Stop service + start the java process manually (see CMD below).
# Hint: changing the shell to bash via chsh is optional.
RUN service scc_daemon stop && chsh -s /bin/bash sccadmin

# expose connector server
EXPOSE 8443
USER sccadmin
WORKDIR /opt/sap/scc

# finally run sapcc as PID 1
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

#CMD ["/opt/sapjvm_8/bin/java","-server","-XtraceFile=log/vm_@PID_trace.log","-XX:+GCHistory","-XX:GCHistoryFilename=log/vm_@PID_gc.prf","-XX:+HeapDumpOnOutOfMemoryError","-XX:+DisableExplicitGC","-Xms1024m","-Xmx1024m","-XX:MaxNewSize=512m","-XX:NewSize=512m","-XX:+UseConcMarkSweepGC","-XX:TargetSurvivorRatio=85","-XX:SurvivorRatio=6","-XX:MaxDirectMemorySize=2G","-Dorg.apache.tomcat.util.digester.PROPERTY_SOURCE=com.sap.scc.tomcat.utils.PropertyDigester","-Dosgi.requiredJavaVersion=1.6","-Dosgi.install.area=.","-DuseNaming=osgi","-Dorg.eclipse.equinox.simpleconfigurator.exclusiveInstallation=false","-Dcom.sap.core.process=ljs_node","-Declipse.ignoreApp=true","-Dosgi.noShutdown=true","-Dosgi.framework.activeThreadType=normal","-Dosgi.embedded.cleanupOnSave=true","-Dosgi.usesLimit=30","-Djava.awt.headless=true","-Dio.netty.recycler.maxCapacity.default=256","-jar plugins/org.eclipse.equinox.launcher_1.1.0.v20100507.jar"]

#HINT:
# The CMD above is basically derived from the SAPCC "portable" archives which can be
# downloaded from https://tools.hana.ondemand.com/#cloud, i.e. sapcc-2.11.3-windows-x64.zip, sapcc-2.11.-linux-x64.tar.gz, sapcc-2.11.3-macosx-x64.tar.gz
# To verify this, simply extract any of these archives and check the files "deamon.sh" and "props.ini".
# The first 4 option in CMD are derived from deamon.sh, all other options are derived from the props.ini file.
