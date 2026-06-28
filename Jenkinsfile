pipeline {
    agent any

    parameters {
        string(
            name: 'APP_VERSION',
            defaultValue: '',
            description: 'Версия приложения в формате v1.0.0 (оставьте пустым для использования git тега)'
        )
    }

    environment {
        APP_ENV = 'prod'
        XDEBUG_MODE = 'off'
    }

    stages {
        stage('Checkout') {
            steps {
                echo "Checking out repository"
                checkout scm
            }
        }

        stage('Set Version') {
            steps {
                script {
                    if (params.APP_VERSION?.trim()) {
                        // Используем введённую версию
                        env.APP_VERSION = params.APP_VERSION.trim()
                        echo "Using manual version: ${env.APP_VERSION}"
                    } else {
                        // Получаем версию из git
                        env.APP_VERSION = sh(
                            script: "git describe --tags --always --dirty 2>/dev/null || echo 'dev'",
                            returnStdout: true
                        ).trim()
                        echo "Using git version: ${env.APP_VERSION}"
                    }

                    // Формируем имя архива
                    def timestamp = new Date().format('yyyyMMdd-HHmmss')
                    env.ARCHIVE_NAME = "app-${env.APP_VERSION}-${timestamp}.tar.gz"

                    echo "Final archive name: ${env.ARCHIVE_NAME}"
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                    # Production-установка без dev-зависимостей
                    composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader --classmap-authoritative
                '''
            }
        }

        stage('Build Frontend') {
            steps {
                sh '''
                    # Если есть Webpack Encore или AssetMapper
                    if [ -f package.json ]; then
                        npm ci --production
                        npm run build
                    fi
                '''
            }
        }

        stage('Warmup Cache') {
            steps {
                sh '''
                    php bin/console cache:clear --env=prod --no-debug
                    php bin/console cache:warmup --env=prod
                '''
            }
        }

        stage('Create Archive') {
            steps {
                script {
                    sh '''
                        mkdir -p build

                        tar czf build/${env.ARCHIVE_NAME} \
                            --exclude='.git' \
                            --exclude='.gitignore' \
                            --exclude='.env' \
                            --exclude='.env.*' \
                            --exclude='node_modules' \
                            --exclude='tests' \
                            --exclude='var/cache' \
                            --exclude='var/log' \
                            --exclude='var/sessions' \
                            --exclude='vendor/bin' \
                            --exclude='build' \
                            --exclude='docker' \
                            --exclude='docker-compose.*' \
                            --exclude='Dockerfile' \
                            --exclude='Jenkinsfile' \
                            --exclude='phpunit.xml.dist' \
                            --exclude='.php-cs-fixer.dist.php' \
                            --exclude='phpstan.neon' \
                            --exclude='psalm.xml' \
                            --exclude='README.md' \
                            --exclude='.github' \
                            --exclude='.gitlab-ci.yml' \
                            .

                        echo "Archive created: build/${ARCHIVE_NAME}"
                    '''
                }
            }
        }

        stage('Verify Archive') {
            steps {
                sh '''
                    echo "=== Archive contents ==="
                    tar tzf build/${ARCHIVE_NAME} | head -30

                    echo ""
                    echo "=== Checking required files ==="
                    tar tzf build/${ARCHIVE_NAME} | grep -E "(composer.json|bin/console|public/index.php)" || {
                        echo "ERROR: Required files missing!"
                        exit 1
                    }
                '''
            }
        }
    }

    post {
    success {
        script {
            sh "echo '${env.APP_VERSION}' > build/VERSION.txt"

                archiveArtifacts(
                    artifacts: "build/${env.ARCHIVE_NAME}, build/VERSION.txt",
                    fingerprint: true,
                    onlyIfSuccessful: true
                )

                def archiveSize = sh(
                    script: "du -h build/${env.ARCHIVE_NAME} | cut -f1",
                    returnStdout: true
                ).trim()

                echo """
                    =========================================
                    ✅ Archive ready
                    📦 Version: ${env.APP_VERSION}
                    📁 File: ${env.ARCHIVE_NAME}
                    💾 Size: ${archiveSize}
                    📥 Download from Jenkins artifacts
                    =========================================
                """
        }
    }
}
}
