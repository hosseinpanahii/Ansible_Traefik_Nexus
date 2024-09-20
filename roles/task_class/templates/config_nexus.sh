#!/bin/bash

# variable section
ADMIN_USERNAME={{ NEXUS_ADMIN_USERNAME }}
ADMIN_PASSWORD={{ NEXUS_ADMIN_PASSWORD }}
ADMIN_PASSWORD=admin
NEXUS_URL={{ NEXUS_SERVICE_URL }}
REPO_USERNAME={{ NEXUS_REPO_USERNAME }}
REPO_PASSWORD={{ NEXUS_REPO_PASSWORD }}
REPO_EMAIL={{ NEXUS_REPO_EMAIL }}
DOCKER_REPO_BLOBSTORE={{ DOCKER_REPO_BLOBSTORE }}
DOCKER_REPO_HOSTED_BLOBSTORE={{ DOCKER_REPO_HOSTED_BLOBSTORE }}
DOCKER_REPO_APT_BLOBSTORE={{ DOCKER_REPO_APT_BLOBSTORE }}
# -----------------------------------------------------
# writable state
curl -k -X 'GET' \
  ''${NEXUS_URL}'/service/rest/v1/status/writable' \
  -H 'accept: application/json'


Nexus_Health=$(curl -k -X 'GET' ''${NEXUS_URL}'/service/rest/v1/status/writable' -H 'accept: application/json' 2>/dev/null)
echo ${Nexus_Health}

until [ -z "$Nexus_Health" ]
do
    Nexus_Health=$(curl -k -X 'GET' ''${NEXUS_URL}'/service/rest/v1/status/writable' -H 'accept: application/json' 2>/dev/null)
    echo ${Nexus_Health}
    echo "Waiting for nexus starting..."
    echo ${TIME}
    TIME=$((TIME+1))
    echo
    sleep 1
done
echo "nexus writable state is ok"

# get bootstrap password
BOOTSTRAP_ADMIN_PASSWORD=$(docker exec -i nexus cat sonatype-work/nexus3/admin.password)
echo ${BOOTSTRAP_ADMIN_PASSWORD}

# change password
curl -k -X 'PUT' \
  ''${NEXUS_URL}'/service/rest/v1/security/users/admin/change-password' \
  -u "admin:${BOOTSTRAP_ADMIN_PASSWORD}" \
  -H 'accept: application/json' \
  -H 'Content-Type: text/plain' \
  -d ''${ADMIN_PASSWORD}''

# delete default repository
curl -k -X 'DELETE' \
  ''${NEXUS_URL}'/service/rest/v1/repositories/maven-releases' \
  -u "${ADMIN_USERNAME}:${ADMIN_PASSWORD}" \
  -H 'accept: application/json'

curl -k -X 'DELETE' \
  ''${NEXUS_URL}'/service/rest/v1/repositories/maven-snapshots' \
  -u "${ADMIN_USERNAME}:${ADMIN_PASSWORD}" \
  -H 'accept: application/json'

curl -k -X 'DELETE' \
  ''${NEXUS_URL}'/service/rest/v1/repositories/maven-central' \
  -u "${ADMIN_USERNAME}:${ADMIN_PASSWORD}" \
  -H 'accept: application/json'

curl -k -X 'DELETE' \
  ''${NEXUS_URL}'/service/rest/v1/repositories/maven-public' \
  -u "${ADMIN_USERNAME}:${ADMIN_PASSWORD}" \
  -H 'accept: application/json'

curl -k -X 'DELETE' \
  ''${NEXUS_URL}'/service/rest/v1/repositories/nuget.org-proxy' \
  -u "${ADMIN_USERNAME}:${ADMIN_PASSWORD}" \
  -H 'accept: application/json'

curl -k -X 'DELETE' \
  ''${NEXUS_URL}'/service/rest/v1/repositories/nuget-group' \
  -u "${ADMIN_USERNAME}:${ADMIN_PASSWORD}" \
  -H 'accept: application/json'

curl -k -X 'DELETE' \
  ''${NEXUS_URL}'/service/rest/v1/repositories/nuget-hosted' \
  -u "${ADMIN_USERNAME}:${ADMIN_PASSWORD}" \
  -H 'accept: application/json'

# disable anonymous access
curl -k -X 'PUT' \
  ''${NEXUS_URL}'/service/rest/v1/security/anonymous' \
  -u "${ADMIN_USERNAME}:${ADMIN_PASSWORD}" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "enabled": false
}'

# activate realms
curl -k -X 'PUT' \
  ''${NEXUS_URL}'/service/rest/v1/security/realms/active' \
  -u "${ADMIN_USERNAME}:${ADMIN_PASSWORD}" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '[
  "NexusAuthenticatingRealm",
  "DockerToken"
]'

# create role
curl -k -X 'POST' \
  ''${NEXUS_URL}'/service/rest/v1/security/roles' \
  -u "${ADMIN_USERNAME}:${ADMIN_PASSWORD}" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "id": "repo-admin",
  "name": "repo-admin",
  "description": "all repository admin",
  "privileges": [
    "nx-repository-admin-*-*-*"
  ]
}'

# create user
curl -k -X 'POST' \
  ''${NEXUS_URL}'/service/rest/v1/security/users' \
  -u "${ADMIN_USERNAME}:${ADMIN_PASSWORD}" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "userId": "'${REPO_USERNAME}'",
  "firstName": "'${REPO_USERNAME}'",
  "lastName": "afranet",
  "emailAddress": "'${REPO_EMAIL}'",
  "password": "'${REPO_PASSWORD}'",
  "status": "active",
  "roles": [
    "repo-admin",
    "nx-anonymous"
  ]
}'

# create blobstore
curl -k -X 'POST' \
  ''${NEXUS_URL}'/service/rest/v1/blobstores/file' \
  -u "${ADMIN_USERNAME}:${ADMIN_PASSWORD}" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "softQuota": {
    "type": "spaceRemainingQuota",
    "limit": 102400
  },
  "path": "'${DOCKER_REPO_BLOBSTORE}'",
  "name": "'${DOCKER_REPO_BLOBSTORE}'"
}'
#create second blobstore for docker hosted
curl -k -X 'POST' \
  ''${NEXUS_URL}'/service/rest/v1/blobstores/file' \
  -u "${ADMIN_USERNAME}:${ADMIN_PASSWORD}" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "softQuota": {
    "type": "spaceRemainingQuota",
    "limit": 102400
  },
  "path": "'${DOCKER_REPO_HOSTED_BLOBSTORE}'",
  "name": "'${DOCKER_REPO_HOSTED_BLOBSTORE}'"
}'

#create third blobstore for apt repo
curl -k -X 'POST' \
  ''${NEXUS_URL}'/service/rest/v1/blobstores/file' \
  -u "${ADMIN_USERNAME}:${ADMIN_PASSWORD}" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "softQuota": {
    "type": "spaceRemainingQuota",
    "limit": 102400
  },
  "path": "'${DOCKER_REPO_APT_BLOBSTORE}'",
  "name": "'${DOCKER_REPO_APT_BLOBSTORE}'"
}'

# create docker proxy repository 
curl -k -X 'POST' \
  ''${NEXUS_URL}'/service/rest/v1/repositories/docker/proxy' \
  -u "${ADMIN_USERNAME}:${ADMIN_PASSWORD}" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "name": "docker-private-registry",
  "online": true,
  "storage": {
    "blobStoreName": "'${DOCKER_REPO_BLOBSTORE}'",
    "strictContentTypeValidation": true
  },
  "cleanup": {
    "policyNames": [
      "string"
    ]
  },
  "proxy": {
    "remoteUrl": "https://registry.docker.ir",
    "contentMaxAge": 1440,
    "metadataMaxAge": 1440
  },
  "negativeCache": {
    "enabled": true,
    "timeToLive": 1440
  },
  "httpClient": {
    "blocked": false,
    "autoBlock": true
  },
  "routingRule": "string",
  "docker": {
    "v1Enabled": true,
    "forceBasicAuth": false,
    "httpPort": 8082
  },
  "dockerProxy": {
    "indexType": "REGISTRY"
  }
}'
# Create Docker Hosted repository
curl -k -X 'POST' \
  ''${NEXUS_URL}'/service/rest/v1/repositories/docker/hosted' \
  -u "${ADMIN_USERNAME}:${ADMIN_PASSWORD}" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "name": "docker-private-hosted",
  "online": true,
  "storage": {
    "blobStoreName": "'${DOCKER_REPO_HOSTED_BLOBSTORE}'",
    "strictContentTypeValidation": true,
    "writePolicy": "allow_once",
    "latestPolicy": true
  },
  "cleanup": {
    "policyNames": [
      "string"
    ]
  },
  "component": {
    "proprietaryComponents": true
  },
  "docker": {
    "v1Enabled": false,
    "forceBasicAuth": true,
    "httpPort": 8083,
  }
}'

#create docker apt  repository
curl -k -X 'POST' \
  ''${NEXUS_URL}'/service/rest/v1/repositories/apt/proxy' \
  -u "${ADMIN_USERNAME}:${ADMIN_PASSWORD}" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "name": "apt-debian",
  "online": true,
  "storage": {
    "blobStoreName":  "'${DOCKER_REPO_APT_BLOBSTORE}'",
    "strictContentTypeValidation": true
  },
  "cleanup": {
    "policyNames": [
      "string"
    ]
  },
  "proxy": {
    "remoteUrl": "http://mirror.arvancloud.ir/debian ",
    "contentMaxAge": 1440,
    "metadataMaxAge": 1440
  },
  "negativeCache": {
    "enabled": true,
    "timeToLive": 1440
  },
  "httpClient": {
    "blocked": false,
    "autoBlock": true,
    "connection": {
      "retries": 0,
      "userAgentSuffix": "string",
      "timeout": 60,
      "enableCircularRedirects": false,
      "enableCookies": false,
      "useTrustStore": false
    }
   },
  "routingRule": "string",
  "replication": {
    "preemptivePullEnabled": false,
    "assetPathRegex": "string"
  },
  "apt": {
    "distribution": "bookwork",
    "flat": false
  }

}'

#create docker apt security repository
curl -k -X 'POST' \
  ''${NEXUS_URL}'/service/rest/v1/repositories/apt/proxy' \
  -u "${ADMIN_USERNAME}:${ADMIN_PASSWORD}" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "name": "apt--security-debian",
  "online": true,
  "storage": {
    "blobStoreName":  "'${DOCKER_REPO_APT_BLOBSTORE}'",
    "strictContentTypeValidation": true
  },
  "cleanup": {
    "policyNames": [
      "string"
    ]
  },
  "proxy": {
    "remoteUrl": "http://mirror.arvancloud.ir/debian-security ",
    "contentMaxAge": 1440,
    "metadataMaxAge": 1440
  },
  "negativeCache": {
    "enabled": true,
    "timeToLive": 1440
  },
  "httpClient": {
    "blocked": false,
    "autoBlock": true,
    "connection": {
      "retries": 0,
      "userAgentSuffix": "string",
      "timeout": 60,
      "enableCircularRedirects": false,
      "enableCookies": false,
      "useTrustStore": false
    }
   },
  "routingRule": "string",
  "replication": {
    "preemptivePullEnabled": false,
    "assetPathRegex": "string"
  },
  "apt": {
    "distribution": "bookwork",
    "flat": false
  }
}'
## check all repositories
#curl -k -X 'GET' \
#  ''${NEXUS_URL}'/service/rest/v1/repositories' \
#  -u "${ADMIN_USERNAME}:${ADMIN_PASSWORD}" \
#  -H 'accept: application/json'
#
## check all blobstore
#curl -k -X 'GET' \
#  ''${NEXUS_URL}'/service/rest/v1/blobstores' \
#  -u "${ADMIN_USERNAME}:${ADMIN_PASSWORD}" \
#  -H 'accept: application/json'
#
## check all users and roles
#curl -k -X 'GET' \
#  ''${NEXUS_URL}'/service/rest/v1/security/users' \
#  -u "${ADMIN_USERNAME}:${ADMIN_PASSWORD}" \
#  -H 'accept: application/json'
#
#curl -k -X 'GET' \
#  ''${NEXUS_URL}'/service/rest/v1/security/roles' \
#  -u "${ADMIN_USERNAME}:${ADMIN_PASSWORD}" \
#  -H 'accept: application/json'
