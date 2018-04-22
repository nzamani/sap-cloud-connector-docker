# SAP Cloud Connector in Docker

Easily setup SAPCC in docker.

## Instructions

1. Install [Docker](https://www.docker.com/community-edition)

1. Install [Git](https://git-scm.com)

On Windows I suggest to install Git Bash as well (you'll be asked during the installation process).

**Hint:** Installing git is actually not really needed. Alternatively, you could also copy/download this Dockerfile to yor machine.

1. Clone this repo

```sh
git clone https://github.com/nzamani/sap-cloud-connector-docker.git
cd sap-cloud-connector-docker
```

1. Build the Docker image

```sh
docker build -t sapcc:2.11.0.3 .
```

1. Create a container running as a deamon

    - Use this if you want to map the default SAP ports as they come on localhost (preferred)

        ```sh
        docker run -p 8443:8443 -h mysapcc --name sapcc -d sapcc:2.11.0.3
        ```

    - Use this one if "random" ports on localhost are fine for you

        ```sh
        docker run -P -h mysapcc --name sapcc -d sapcc:2.11.0.3
        ```

1. Starting/Stopping the container

    - **Starting:** `docker start sapcc`
    - **Stopping:** `docker stop sapcc`

1. Post Installation Steps

    Logon to [https://localhost:8443](https://localhost:8443) with the default credentials:

      - **User:** Administrator
      - **Password:** manage

    You will be asked to change your password.


## Docker Configuration and Commands

### Creating a Network called `saptrial`

```sh
docker network create -d bridge saptrial
```

### Connect Container `sapcc` to Network `saptrial` + make `sapcc` available via alias `mysapcc`

```sh
docker network connect --alias mysapcc saptrial sapcc
```

### Putting an existing NW ABAP Container onto the same Network (with different aliases)

```sh
docker network connect --alias vhcalnplci saptrial nwabap751
docker network connect --alias vhcalnplci.dummy.nodomain saptrial nwabap751
```

### Removing Containers from Docker Networks

```sh
docker network disconnect saptrial nwabap751
docker network disconnect saptrial sapcc
```

### Deleting/Removing a Docker Network

```sh
docker network rm saptrial
```

### Creating a Docker Image from Docker Containers (i.e. for "backup")

```sh
# Suggestion: stop the container you want to backup before continuing
docker stop sapcc

# create an image "sapccbackup" from the container "sapcc"
docker commit sapcc sapccbackup:1
# later you can create a new container from the new image "sapccimage"
# Hint: if the ports etc are already used by other containers you must use different ports (or i.e. deleting the other containers first)
docker run -p 8443:8443 -h mysapcc --name sapccNewContainer -d sapccbackup:1
```

## Additional Resources

1. **Youtube:** [SAP HANA Academy - SAP CP: Blueprint #1.4: Cloud Connector Principal Propagation](https://www.youtube.com/watch?v=eo359fUZSJA)

1. **Youtube:** [SAP HANA Academy - SAP CP: Blueprint #1.5 ABAP Principal Propagation](https://www.youtube.com/watch?v=cbQ8Fy9TBbY)

1. **Youtube:** [SAP HANA Academy - SAP CP: Blueprint #1.6: Principal Propagation using X509 certificates](https://www.youtube.com/watch?v=gt_Ja9ldHnY)

1. **SAP Help:** [Creating a Self-Signed Root Certificate Authority](https://help.hana.ondemand.com/hana_cloud_platform_mobile_services_preview/frameset.htm?590e173911084f17b73caff26f79a4ae.html)

1. **SAP Help:** [Creating Intermediate Certificates](https://help.hana.ondemand.com/hana_cloud_platform_mobile_services_preview/frameset.htm?713d30fa7aa346f39896acd1229dc06f.html)

1. **SAP Community:** [How to Guide – Principal Propagation in an HTTPS Scenario](https://blogs.sap.com/2017/06/22/how-to-guide-principal-propagation-in-an-https-scenario/)
