pipeline {
    agent any
    
    triggers {
      pollSCM ''
    }

    stages {
        stage('Iniciando') {
            steps {
                echo 'Inicio'
            }
        }
        stage('Procesando') {
            steps {
                echo 'Proceso'
            }
        }
        stage('Publicando') {
            steps {
                echo 'Publicación'
            }
        }
    }
}
