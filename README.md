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



`src/shared/Constandts.lua`

눈덩이 피해량, 라운드 시간 등 고정값들

`src/server/DataService.lua`

