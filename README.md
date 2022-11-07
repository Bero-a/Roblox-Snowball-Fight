# Snowball-Fight

```bash
wally install
```

## 스크립트별 간단한 설명

### Client-Side

`src\client\Components\ClientSnowballer.lua`

클릭했을 때를 감지해서 던지는 힘을 모으거나, GUI를 변경하거나, 소리를 재생하는 등의 역할을 함

`src\client\Controllers\GameStateController.lua`

게임의 상태와 관련된 GUI

`src/shared/Constandts.lua`

눈덩이 피해량, 라운드 시간 등 고정값들

`src/server/DataService.lua`

