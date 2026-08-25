// porest-desk-app 배포 — 다른 porest 레포와 같이 Jenkinsfile 을 레포에 둔다.
//
// 다른 레포와 다른 점이 하나 있다. 앱은 여기서 빌드하지 않는다.
// APK 는 안드로이드 SDK, IPA 는 macOS 러너가 필요해서 GitHub Actions 가 빌드하고
// Release 에 붙여 둔다. Jenkins 는 그걸 받아 서버에 놓기만 한다.
//
// 그래서 Docker 이미지도, 컨테이너도 없다. 정적 파일을 nginx 가 내보낼 자리에
// 옮기는 게 전부다(.github/jenkins/deploy.sh).
//
// 실행은 Actions 가 웹훅으로 건다. 값은 플러그인이 환경변수로 넣어 주므로
// params 가 아니라 env 로 읽는다 — parameters 를 선언하면 같은 이름끼리 부딪힌다.
//
// 트리거 설정 자체(Generic Webhook Trigger 의 토큰 · genericVariables 매핑)는 이 파일이
// 아니라 Jenkins 잡 설정에 있다. 다른 porest 레포와 같다 — 여기에 triggers 블록을 되살리지
// 마라. Declarative 의 triggers 디렉티브는 빌드가 돌 때마다 잡 설정에 다시 적용돼서,
// UI 에서 토큰을 바꿔도 다음 빌드에 파일에 적힌 값으로 되돌아간다. 그리고 그 토큰은 인증
// 없이 배포를 거는 열쇠라 레포에 평문으로 둘 수 없다(Jenkins 는 인터넷에서 열려 있다).
//
// 잡 설정에 있어야 하는 것 — 토큰, 그리고 genericVariables 두 줄:
// CHANNEL = $.channel · VERSION = $.version. 하나라도 빠지면 아래 Validate 가 막는다.
pipeline {
    agent any

    environment {
        // 다른 레포와 같은 전역변수를 쓴다. Jenkins 전역 설정에서 한 번만 정한다.
        APK_BASE_PATH = "${env.POREST_BASE_DIR}/apk"
        APK_REPO = 'lshdainty/porest-desk-app'
    }

    stages {
        stage('Validate') {
            steps {
                script {
                    // 웹훅 표현식이 안 맞으면 값이 통째로 비어 온다. 승인을 받기 전에 막는다 —
                    // 잘못 배포되느니 여기서 실패하는 게 낫다.
                    if (!env.CHANNEL || !env.VERSION) {
                        error "웹훅에서 CHANNEL·VERSION 을 못 읽었습니다 (CHANNEL='${env.CHANNEL}', VERSION='${env.VERSION}')"
                    }
                    if (!(env.CHANNEL in ['dev', 'prod'])) {
                        error "CHANNEL 은 dev 또는 prod 여야 합니다: ${env.CHANNEL}"
                    }
                    echo "배포 대상: ${env.CHANNEL} ${env.VERSION}"
                }
            }
        }

        stage('Approval for Prod') {
            when { expression { env.CHANNEL == 'prod' } }
            steps {
                script {
                    // 운영만 멈춘다. 누르기 전에는 서버에 아무것도 놓이지 않는다.
                    input(
                        id: 'DeployToProd',
                        message: "운영에 ${env.VERSION} 배포하시겠습니까?",
                        ok: '배포'
                    )
                }
            }
        }

        stage('Deploy') {
            steps {
                // 배포 절차는 deploy.sh 한 벌뿐이다. dev·prod 가 같은 길을 걷게 해서
                // 한쪽만 고쳐져 어긋나는 일을 없앤다.
                //
                // 홑따옴표라 Groovy 가 아니라 셸이 값을 푼다 — 웹훅으로 들어온 값을
                // 스크립트 문자열에 그대로 박아 넣지 않는다.
                sh './.github/jenkins/deploy.sh "$CHANNEL" "$VERSION"'
            }
        }
    }
}
