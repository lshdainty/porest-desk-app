# 앱 배포

스토어를 쓰지 않고 **서버에서 직접 받아 설치**한다. 안드로이드가 주 경로이고, iOS 는
서명 없이 빌드한 IPA 를 올려 두되 설치는 받는 사람이 직접 서명해야 한다.

**빌드는 GitHub Actions, 배포는 Jenkins.** 다른 porest 레포와 같다 — 운영에 무엇이
언제 올라가는지는 Jenkins 한 곳에서만 통제한다.

## 흐름

```
main 머지        → 검증 → 빌드 → dev 릴리스   → Jenkins 호출 → dev 로 배포 (자동)
태그 vX.Y.Z 푸시 → 검증 → 빌드 → 정식 릴리스  → Jenkins 호출 → [승인] → prod 로 배포
```

Actions 는 **서버로 아무것도 밀지 않는다.** 빌드 결과를 GitHub Release 에 붙이고
Jenkins 에 "새 게 나왔다" 고 알릴 뿐이다. 파일을 서버에 놓는 건 Jenkins 가 한다.

그래서 Actions 에는 서버 주소도, SSH 키도 없다. 서명 키 4개면 된다.

### 왜 밀지 않고 가져가나

밀어넣는 방식이면 GitHub 이 내 서버에 로그인할 수 있어야 해서 SSH 개인키를 통째로
넘겨야 한다. 가져가는 방식이면 그럴 이유가 없고, 승인 지점이 Actions 와 Jenkins 로
갈리지도 않는다.

Actions **artifact** 는 공개 레포라도 받으려면 토큰이 필요하지만 **Release** 는 아니다.
그래서 artifact 가 아니라 Release 로 넘긴다. 덤으로 artifact 의 7일 만료도 없어진다.

## 버전

`versionCode` 가 단조 증가해야 재설치 없이 업데이트된다.

| | version name | versionCode | 릴리스 태그 |
|---|---|---|---|
| dev | pubspec 의 `X.Y.Z` | Actions 실행번호 | `dev` (프리릴리스, 매번 덮어씀) |
| prod | 태그에서 딴 `X.Y.Z` | Actions 실행번호 | `vX.Y.Z` |

실행번호는 레포 전역으로 늘어나므로 dev/prod 가 번갈아 나가도 역전이 없다.

`dev` 태그는 빌드마다 지웠다 다시 만든다 — 최신 하나만 남기려는 것이다.

## Flutter 버전

워크플로의 `FLUTTER_VERSION` 은 로컬(`.fvmrc`)과 **같은 값으로 고정**한다. CI 만
최신 stable 을 따라가면 SDK 가 올라갈 때마다 로컬은 통과하는데 CI 만 깨진다
(`flutter analyze` 는 deprecation info 도 실패로 친다).

SDK 를 올릴 때는 두 곳을 함께 바꾼다.

## 준비 (한 번만)

### 1. 서명 키

**한 번 정하면 앱 수명 내내 바꿀 수 없다.** 키가 달라지면 기존 설치본 위에 업데이트가
안 되고, 지우고 새로 깔아야 한다(데이터도 사라진다).

```bash
keytool -genkey -v -keystore porest-desk.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias porest-desk
```

**jks 파일은 안전한 곳에 백업할 것.**

Secrets 에 4개 등록. 값을 셸 히스토리에 남기지 않으려면 `gh secret set` 을 인자 없이
불러 프롬프트에 입력한다.

```bash
R=lshdainty/porest-desk-app
# 줄바꿈이 섞이면 base64 디코드가 깨진다 — -w0 로 한 줄로 만든다
base64 -w0 porest-desk.jks | gh secret set ANDROID_KEYSTORE_BASE64 -R "$R"
gh secret set ANDROID_KEYSTORE_PASSWORD -R "$R"   # keystore 비밀번호
gh secret set ANDROID_KEY_PASSWORD      -R "$R"   # key 비밀번호
echo -n porest-desk | gh secret set ANDROID_KEY_ALIAS -R "$R"
```

키가 없어도 빌드는 된다 — 디버그 키로 서명될 뿐이다. 채우는 순간부터 릴리스 키로 바뀐다.

### 2. Jenkins 호출용 Secret

| 이름 | 값 |
|---|---|
| `JENKINS_URL` | 다른 porest 레포에 등록해 둔 값과 같다 |

비어 있으면 릴리스까지만 하고 호출은 건너뛴다 — CI 가 빨간불이 되지는 않는다.

### 3. Jenkins job 2개

Generic Webhook Trigger 로 받는다. 토큰 이름은 다른 레포와 같은 규칙이다.

| job | 토큰 | 승인 |
|---|---|---|
| dev | `porest-desk-app-deploy` | 없음 |
| prod | `porest-desk-app-deploy-prod` | **있음** |

Actions 가 JSON 본문으로 `channel`·`version`·`tag`·`buildNumber` 를 보낸다.
**Post content parameters** 에 `CHANNEL ← $.channel`, `VERSION ← $.version` 을 걸어 둔다.

Pipeline (prod):

```groovy
pipeline {
  agent any
  stages {
    stage('승인') {
      steps {
        // 여기서 멈춘다. 누르기 전에는 서버에 아무것도 놓이지 않는다.
        input message: "운영에 ${params.VERSION} 배포할까요?", ok: '배포'
      }
    }
    stage('배포') {
      steps {
        git url: 'https://github.com/lshdainty/porest-desk-app.git', branch: 'main'
        sh "./.github/jenkins/deploy.sh ${params.CHANNEL} ${params.VERSION}"
      }
    }
  }
}
```

dev job 은 `승인` 단계만 빼면 같다.

배포 스크립트는 레포 안에 있다 — [.github/jenkins/deploy.sh](jenkins/deploy.sh).
Jenkins 설정에 복붙해 두면 고칠 때마다 두 곳을 맞춰야 해서, 레포에 두고 job 은
실행만 시킨다.

경로를 바꾸려면 job 환경변수 `APK_BASE_PATH` 를 준다 (기본 `/home/porest/porest/apk`).

서버에 디렉토리를 만들어 둔다.

```bash
mkdir -p /home/porest/porest/apk/{dev,prod}
```

### 4. nginx

정적 파일만 내보낸다. 업로드·실행 경로는 두지 않는다.

```nginx
# APK/IPA 배포 — 파일명을 정규식으로 묶어 경로 탈출을 원천 차단한다.
location ~ ^/download/(?<f>[A-Za-z0-9._-]+\.(apk|ipa|json))$ {
    alias /home/porest/porest/apk/prod/$f;
    autoindex off;
    limit_rate 3m;
    add_header X-Content-Type-Options nosniff;
}
# 위 패턴에 안 맞는 /download/ 요청은 전부 막는다(목록 노출·탐색 방지).
location /download/ { return 404; }
```

## iOS

`porest-desk-X.Y.Z.ipa` 는 **서명이 없다.** 받는 사람이 자기 Apple ID 로 서명해 넣어야
하고(AltStore·Sideloadly), 무료 Apple ID 로 서명하면 **7일마다 다시 서명**해야 한다.
개발자 계정은 필요 없지만 각자 PC 가 필요하다 — 일반 사용자에게 권할 경로는 아니고,
웹으로 안내하는 편이 낫다.
