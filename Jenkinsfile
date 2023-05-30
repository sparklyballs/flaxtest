pipeline {
	agent {
	label 'DOCKER_BUILD_X86_64'
	}

options {
	skipDefaultCheckout(true)
	}

environment {
	CREDS_DOCKERHUB=credentials('420d305d-4feb-4f56-802b-a3382c561226')
	CREDS_GITHUB=credentials('bd8b00ff-decf-4a75-9e56-1ea2c7d0d708')
	CONTAINER_NAME = 'flaxtest'
	CONTAINER_REPOSITORY = 'sparklyballs/flaxtest'
	HADOLINT_OPTIONS = '--ignore DL3008 --ignore DL3013 --ignore DL3018 --ignore DL3028 --format json'
	RELEASE_URL = 'https://api.github.com/repos/Flax-Network/flax-blockchain/releases/latest'
	}

stages {

stage('Query Release Version') {
steps {
script{
	env.RELEASE_VER = sh(script: 'curl -sX GET "${RELEASE_URL}" | jq -r ".tag_name"', returnStdout: true).trim() 
	}
	}
	}

stage('Checkout Repository') {
steps {
	cleanWs()
	checkout scm
	}
	}

stage ("Do Some Linting") {
steps {
	sh ('docker pull ghcr.io/hadolint/hadolint')
	sh ('docker run \
	--rm  -i \
	-v $WORKSPACE/Dockerfile:/Dockerfile \
	ghcr.io/hadolint/hadolint \
	hadolint $HADOLINT_OPTIONS \
	/Dockerfile | tee hadolint_lint.txt')
	}
	}

stage('Build Docker Image') {
steps {
	sh ('docker buildx build \
	--no-cache \
	--pull \
	-t $CONTAINER_REPOSITORY:latest \
	-t $CONTAINER_REPOSITORY:$RELEASE_VER \
	--build-arg RELEASE=$RELEASE_VER \
	.')
	}
	}

stage('Push Docker Image and Tags') {
steps {
	sh ('echo $CREDS_DOCKERHUB_PSW | docker login -u $CREDS_DOCKERHUB_USR --password-stdin')
	sh ('docker image push $CONTAINER_REPOSITORY:latest')
	sh ('docker image push $CONTAINER_REPOSITORY:$RELEASE_VER')
	}
	}

}

post {
always {
	recordIssues enabledForFailure: true, tool: hadoLint(pattern: 'hadolint_lint.txt')	
	}
	}
}
