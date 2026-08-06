# 앱 배포

스토어를 쓰지 않고 **서버에서 직접 받아 설치**한다. 안드로이드가 주 경로이고, iOS 는
서명 없이 빌드한 IPA 를 올려 두되 설치는 받는 사람이 직접 서명해야 한다.

## 흐름

```
main 머지        → 검증 → 빌드 → dev 로 배포 (자동)
태그 vX.Y.Z 푸시 → 검증 → 빌드 → [승인 대기] → prod 로 배포
```

승인은 GitHub Environment(`production`)의 reviewer 로 건다. Actions 실행 화면에
"Review deployments" 버튼이 뜨고, 누르기 전에는 서버에 아무것도 올라가지 않는다.

## 버전

`versionCode` 가 단조 증가해야 재설치 없이 업데이트된다.

| | version name | versionCode |
|---|---|---|
| dev | pubspec 의 `X.Y.Z` | Actions 실행번호 |
| prod | 태그에서 딴 `X.Y.Z` | Actions 실행번호 |

실행번호는 레포 전역으로 늘어나므로 dev/prod 가 번갈아 나가도 역전이 없다.

## 준비 (한 번만)

### 1. 서명 키

**한 번 정하면 앱 수명 내내 바꿀 수 없다.** 키가 달라지면 기존 설치본 위에 업데이트가
안 되고, 지우고 새로 깔아야 한다(데이터도 사라진다).

```bash
keytool -genkey -v -keystore porest-desk.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias porest-desk
base64 -i porest-desk.jks | pbcopy   # 클립보드로
```

**jks 파일은 안전한 곳에 백업할 것.**

Secrets 에 4개 등록:

| 이름 | 값 |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | 위 base64 출력 |
| `ANDROID_KEYSTORE_PASSWORD` | keystore 비밀번호 |
| `ANDROID_KEY_PASSWORD` | key 비밀번호 |
| `ANDROID_KEY_ALIAS` | `porest-desk` |

키가 없어도 빌드는 된다 — 디버그 키로 서명될 뿐이다. 채우는 순간부터 릴리스 키로 바뀐다.

### 2. 배포 서버

Secrets:

| 이름 | 예 |
|---|---|
| `DEPLOY_HOST` | 서버 주소 |
| `DEPLOY_USER` | SSH 계정 |
| `DEPLOY_SSH_KEY` | 개인키 전문 |
| `DEPLOY_APK_PATH` | `/home/porest/porest/apk` |

Variables(Secrets 아님):

| 이름 | 값 |
|---|---|
| `DEPLOY_ENABLED` | `true` — 이걸 켜야 배포 잡이 돈다 |

서버에 디렉토리를 만들어 둔다.

```bash
mkdir -p /home/porest/porest/apk/{dev,prod}
```

### 3. nginx

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

### 4. 승인 게이트

Settings → Environments → `production` 생성 → **Required reviewers** 에 본인 추가.

## iOS

`porest-desk-X.Y.Z.ipa` 는 **서명이 없다.** 받는 사람이 자기 Apple ID 로 서명해 넣어야
하고(AltStore·Sideloadly), 무료 Apple ID 로 서명하면 **7일마다 다시 서명**해야 한다.
개발자 계정은 필요 없지만 각자 PC 가 필요하다 — 일반 사용자에게 권할 경로는 아니고,
웹으로 안내하는 편이 낫다.
