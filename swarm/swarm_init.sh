IP=$(ifconfig | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | head -n 1)
echo $IP

docker swarm init --advertise-addr $IP
docker stack deploy --compose-file docker-compose.yaml mgr

echo "docker service ls...."
docker service ls
