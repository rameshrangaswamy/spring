/**
   artifact related code
**/


def getArtifactoryBuildNameMaster(packageName) {
    return "cjp-${packageName}_service_publishRelease_"
}


def publishCcOneAppPackageMaster(repo, packageName,buildNum) {
    def buildName = getArtifactoryBuildNameMaster(packageName)

    def uploadSpec = payloadForCcOneAppPackageUploadMaster(repo, packageName)
    publishArtifact(buildName, buildNum, uploadSpec)
}

// Function to publish the artifact
def publishArtifact(buildName, buildNum, uploadSpec) {
    def server = Artifactory.server env.ARTIFACTORY_LOCAL_ID

    def buildInfo = Artifactory.newBuildInfo()
    buildInfo.setName buildName
    buildInfo.setNumber buildNum

    server.upload spec: uploadSpec, buildInfo: buildInfo
    server.publishBuildInfo buildInfo
}


def payloadForCcOneAppPackageUploadMaster(repo, packageName) {
    return """{
        "files": [{
            "pattern": "$packageName*.tar",
            "target": "$repo/release/${packageName}/",
            "recursive": "false"
        }]
    }"""
}

return this;

