// Jenkins pipeline snippet to evaluate SonarQube quality gate and fail if gate is not OK
stage('Quality Gate') {
  steps {
    script {
      timeout(time: 2, unit: 'MINUTES') {
        def qg = waitForQualityGate()
        if (qg.status != 'OK') {
          error "Pipeline aborted due to SonarQube Quality Gate: ${qg.status}"
        }
      }
    }
  }
}
