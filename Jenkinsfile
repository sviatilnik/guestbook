pipeline {
    agent any
    
    environment {
        APP_ENV = 'prod'
        XDEBUG_MODE = 'off'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
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
                    // Генерируем имя архива с версией и датой
                    def version = sh(script: "git describe --tags --always --dirty 2>/dev/null || echo 'dev'", returnStdout: true).trim()
                    def timestamp = new Date().format('yyyyMMdd-HHmmss')
                    env.ARCHIVE_NAME = "app-${version}-${timestamp}.tar.gz"
                    env.ARCHIVE_PATH = "build/${env.ARCHIVE_NAME}"
                    
                    sh '''
                        mkdir -p build
                        
                        tar czf ${ARCHIVE_PATH} \
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
                        
                        echo "Archive created: ${ARCHIVE_NAME}"
                        ls -lh ${ARCHIVE_PATH}
                    '''
                }
            }
        }
        
        stage('Verify Archive') {
            steps {
                sh '''
                    echo "=== Archive contents ==="
                    tar tzf ${ARCHIVE_PATH} | head -30
                    
                    echo ""
                    echo "=== Checking required files ==="
                    tar tzf ${ARCHIVE_PATH} | grep -E "(composer.json|bin/console|public/index.php)" || {
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
            archiveArtifacts(
                artifacts: "build/${env.ARCHIVE_NAME}",
                fingerprint: true,
                onlyIfSuccessful: true
            )
            
            // Получаем размер архива через sh
            def archiveSize = sh(
                script: "du -h build/${env.ARCHIVE_NAME} | cut -f1",
                returnStdout: true
            ).trim()
            
            echo """
                ✅ Archive ready: ${env.ARCHIVE_NAME}
                📦 Size: ${archiveSize}
                📥 Download from Jenkins artifacts
            """
        }
    }
}
}
