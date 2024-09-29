# Use a docker compose file

A docker compose file like the one included greatly simplify running and upgrading this
The idea is that you describe your container in a yml file like this: [docker-compose.yml](./docker-compose.yml), and docker compose will sync your actual container with the description

**NOTE** you might have to replace **docker compose** with **docker-compose**, depending on what docker version you're running

## Sync the container (create/update/start)

```sh
docker compose up -d
```

- if you don't have a container this will create one
- if your container is out of date (say you changed the yml file or rebuild the image) it will:
  - stop it
  - destroy it
  - create a new one
  - start it
- if your container is running and up to date, nothing will happen

## Stop the container

```sh
docker compose stop
```

## Update the container to a new version

- build a new image as described in [README](../README.md)
- update the image tag in [docker-compose.yml](./docker-compose.yml)
- sync the container

```sh
docker compose up -d
```

## Remove the container and related resources (except volumes)

```sh
docker compose down
```

Your configuration will be preserved in volumes. If you want to delete those too, add the -v flag. **This will delete your configuration**

## Additional services

A compose file can include several services. For instance you can uncomment the caddy definition and automatically get a valid TLS certificate for your server
This requires ports 80 and 443 of your public IP to be forwarded to this machine
