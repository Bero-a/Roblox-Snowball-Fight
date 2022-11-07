# Snowball-Fight

```bash
wally install
```

bash에서

## 스크립트별 간단한 설명

### Client-side

`src\client\Components\ClientSnowballer.lua`

클릭했을 때를 감지해서 던지는 힘을 모으거나, GUI를 변경하거나, 소리를 재생하는 등의 역할을 함

`src\client\Controllers\GameStateController.lua`

남은 시간, 플레이어 대기 등 게임의 상태와 관련된 GUI를 담당함

`src\client\init.client.lua`

위의 Componnents와 Controllers를 불러오는 역할을 함

### Server-side

`src\server\Components\Snowballer.lua`

플레이어 손에 눈덩이 모델 붙이기, 눈덩이에 맞은 플레이어에게 피해 입히기 등 눈덩이와 관련된, 서버에서 해야 하는 역할을 함 

`src\server\Services\DataService.lua`

플레이어의 전적, 즉 킬 수를 저장하고 불러오며 적을 처치할 떄마다 추가해주는 역할

`src\server\Services\RoundService.lua`

팀을 만들거나, 게임을 시작하거나, 죽은 플레이어를 관전으로 만들거나 하는 등 전체적인 게임 상태 관리

`src\server\Services\SnowballerService.lua`

플레이어 접속 시 항상 눈덩이를 던질 수 있게 해줌

`src\server\init.server.lua`

Client와 마찬가지로 Components와 Services를 불러오는 역할을 함

### ReplicatedStorage

`src\shared\Constants.lua`

눈덩이 피해량, 라운드 시간 등 고정값들을 보관함

## 세부 사항

**components 모듈의 문제**

components 버전 2.1.0(원본 플레이스에 사용)에서는 서버, 클라이언트에서 한 번씩 Components를 지나감(즉, ClientSnowballer.lua의 Snowballer:Start()가 실행됨)

components 버전 2.4.6(직접 패키지 다운로드 시)에서는 서버에서만 지나감(ClientSnowballer의 메서드가 실행되지 않음, 눈덩이 던지는 동작이 마우스 클릭과 연결되지 않음)