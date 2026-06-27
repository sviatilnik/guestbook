pipeline {
    agent any
    options {
        buildDiscarder(logRotator(numToKeepStr: '5'))
    }
    environment {
        COMPOSER_HOME = "${WORKSPACE}/.cache/composer"
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Install Dependencies') {
            steps {
                sh 'composer install --no-interaction --prefer-dist --optimize-autoloader'
            }
        }
        stage('Code Style') {
            steps {
                // Пример для PHP-CS-Fixer
                sh 'vendor/bin/php-cs-fixer fix --dry-run --diff'
            }
        }
        stage('Static Analysis') {
            steps {
                // Если используете PHPStan/Psalm
                sh 'vendor/bin/phpstan analyse src tests --level=5'
            }
        }
        stage('Tests') {
            steps {
                sh '''
            export XDEBUG_MODE=coverage
            vendor/bin/phpunit --configuration phpunit.dist.xml
        '''
            }
        }
        // stage('Deploy') { ... } // Добавите позже
    }
    post {
        always {
            // Сохраняем артефакты (логи, отчёты) даже при падении
            archiveArtifacts artifacts: 'build/*.log, storage/logs/*.log', allowEmptyArchive: true
            junit 'build/reports/phpunit/*.xml' // Парсим результаты тестов для Jenkins
        }
        //failure {
            // Отправляем уведомление в Slack/Telegram/почту
            // slackSend color: 'danger', message: "Сборка ${env.JOB_NAME} #${env.BUILD_NUMBER} упала"
        //}
    }
}
