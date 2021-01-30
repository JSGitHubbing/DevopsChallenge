version: "3.5"
        
services:
    jenkinsdevoss:
        container_name: jenkinsdevoss
        environment:
            - PLUGINS_FORCE_UPGRADE=true # Enforce upgrade of native plugins at startup
        image: devops_jenkins
        ports:
            - "8081:8080"
            - "50000:50000"
            - "443:8443"
        links: 
            - sonarqubedevoss
            - postgres-db-devoss
        dns_search:
          - jenkins.devossteam.com  
        environment:
            external_url:
                "http://jenkins.devossteam.com/"
        volumes:
            - .\docker_volumes\jenkins:/home/jenkins # Allows to write .ssh/known_hosts
            - .\docker_volumes\jenkins_home:/var/jenkins_home
            - .\docker_volumes\jenkins_socket/:/var/run/docker.sock # Jenkins allowed to start/stop containers
            - .\docker_volumes\project_git_repo:/home/project_git_repo

        networks:
            devossnet:
                ipv4_address: 10.0.0.2
                aliases:
                    - "jenkins.devossteam.com"
    sonarqubedevoss:
        container_name: sonarqubedevoss
        image: sonarqube:lts
        ports:
            - "8082:9000"
        networks:
            devossnet:
                ipv4_address: 10.0.0.3  
                aliases:
                    - "sonar.devossteam.com"
        links: 
            - postgres-db-devoss
        dns_search:
          - sonar.devossteam.com   
        volumes:
            - .\docker_volumes\sonarqube_conf:/opt/sonarqube/conf
            - .\docker_volumes\project_git_repo:/home/project_git_repo
            - .\docker_volumes\sonarqube_postgresql:/var/lib/postgresql
            - .\docker_volumes\sonarqube_extensions:/opt/sonarqube/extensions
            - .\docker_volumes\sonarqube_logs:/opt/sonarqube/logs
            - .\docker_volumes\sonarqube_temp:/opt/sonarqube/temp
    nginxserverdevoss:
        image: adoptopenjdk/maven-openjdk11:latest
        build:
            context: .\docker_volumes\project_git_repo
        volumes:
        - .\docker_volumes\project_git_repo:/home/app
        - .\docker_volumnes\nginxserver_/.m2:/root/.m2
        ports:
        - "8008:80"
        container_name: nginxserverdevoss
        networks:
            devossnet:
                ipv4_address: 10.0.0.4  
                aliases:
                    - "nginxserver.devossteam.com"
        links: 
            - postgres-db-devoss
        dns_search:
          - nginxserver.devossteam.com
    postgres-db-devoss:
        container_name: postgres-db-devoss
        image: postgres:10
        environment:
          - POSTGRES_DB=postgres
          - POSTGRES_USER=postgres
          - POSTGRES_PASSWORD=postgres1
        ports:
          - "6000:5432"
        networks:
            devossnet:
                ipv4_address: 10.0.0.5
                aliases:
                    - "postgres-db.devossteam.com"
        dns_search:
          - postgres-db.devossteam.com        
        volumes:
            - .\docker_volumes\postgres_sock:/var/run/postgres/postgres.sock
            - .\docker_volumes\postgres_database:/var/lib/postgresql/data

    
networks:
    devossnet:
        name: devossnet
        driver: bridge
        ipam:
            config:
                - subnet: 10.0.0.1/16
                  gateway: 10.0.0.1
