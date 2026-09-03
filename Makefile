all:	create_dirs
	docker compose -f srcs/docker-compose.yml up --build -d
# --build rebuild images if the Dockerfiles changed
# -d deteached

create_dirs:
	# Create host directories required for persistent volumes
	@mkdir -p /home/dperez-p/data/mariadb
	@mkdir -p /home/dperez-p/data/wordpress

# turn down the containers
down:
	docker compose -f srcs/docker-compose.yml down

clean: down
	docker compose -f srcs/docker-compose.yml down --rmi all

fclean: clean
	sudo rm -rf /home/dperez-p/data/wordpress/*
	sudo rm -rf /home/dperez-p/data/mariadb/*

re: fclean all

.PHONY: all down clean fclean create_dirs re
