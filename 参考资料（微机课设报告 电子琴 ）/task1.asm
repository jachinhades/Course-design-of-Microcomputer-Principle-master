DATA SEGMENT
    ; 键码变量
    KEYCODE DB ?                  ; 当前按键的键码
    FREQ_TABLE_HIGH DW 31, 28, 25, 24, 21, 19, 16 ; 高音分频值表
    FREQ_TABLE_MID  DW 63, 56, 50, 47, 42, 37, 31 ; 中音分频值表
    FREQ_TABLE_LOW  DW 126, 112, 100, 94, 84, 74, 63 ; 低音分频值表
    CURRENT_TABLE DW 0            ; 当前音调分频表指针

    ; 自动演奏数据
    MUSIC_NOTES DB 1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1 ; 音符序列
    MUSIC_DELAY DB 8, 8, 8, 8, 8, 16, 8, 8, 8, 8, 8 ; 节拍时间序列
    NOTE_COUNT DB 11               ; 音符数量
DATA ENDS

CODE SEGMENT
ASSUME CS:CODE, DS:DATA

START:
    ; 初始化数据段
    MOV AX, DATA
    MOV DS, AX

    ; 初始化8254
    CALL INIT_8254

    ; 设置默认音调表为中音
    MOV AX, OFFSET FREQ_TABLE_MID
    MOV CURRENT_TABLE, AX

MAIN_LOOP:
    ; 扫描键盘
    CALL SCAN_KEYBOARD

    ; 检查特殊按键功能
    CMP KEYCODE, 'P'       ; 自动演奏
    JE AUTO_PLAY
    CMP KEYCODE, '1'       ; 切换高音
    JE SHIFT_HIGH
    CMP KEYCODE, '2'       ; 切换低音
    JE SHIFT_LOW

    ; 检查普通按键（高音Q~U, 中音A~J, 低音Z~M）
    CALL MAP_KEY_TO_FREQ
    CALL PLAY_NOTE

    JMP MAIN_LOOP

; 初始化8254计数器
INIT_8254 PROC
    MOV AL, 36H           ; 设置8254计数器为工作方式3，低高字节模式
    OUT 43H, AL           ; 写入控制字寄存器
    RET
INIT_8254 ENDP

; 键盘扫描函数
SCAN_KEYBOARD PROC
    IN AL, 60H            ; 从键盘端口读取键码
    MOV KEYCODE, AL       ; 保存键码
    RET
SCAN_KEYBOARD ENDP

; 按键映射到分频值
MAP_KEY_TO_FREQ PROC
    MOV BX, CURRENT_TABLE ; 获取当前音调表

    ; 检测按键并加载对应频率值
    CMP KEYCODE, 'Q'      ; 高音1
    JE LOAD_FREQ_1
    CMP KEYCODE, 'W'      ; 高音2
    JE LOAD_FREQ_2
    CMP KEYCODE, 'A'      ; 中音1
    JE LOAD_FREQ_3
    CMP KEYCODE, 'S'      ; 中音2
    JE LOAD_FREQ_4
    CMP KEYCODE, 'Z'      ; 低音1
    JE LOAD_FREQ_5

LOAD_FREQ_1:
    MOV AX, [BX]
    JMP SET_FREQ
LOAD_FREQ_2:
    MOV AX, [BX+2]
    JMP SET_FREQ
LOAD_FREQ_3:
    MOV AX, [BX+4]
    JMP SET_FREQ
LOAD_FREQ_4:
    MOV AX, [BX+6]
    JMP SET_FREQ
LOAD_FREQ_5:
    MOV AX, [BX+8]

SET_FREQ:
    RET
MAP_KEY_TO_FREQ ENDP

; 播放单个音符
PLAY_NOTE PROC
    ; 设置分频值到8254
    MOV AL, AH
    OUT 40H, AL          ; 写高字节
    MOV AL, AL
    OUT 40H, AL          ; 写低字节

    ; 延时控制音符长度
    CALL DELAY
    RET
PLAY_NOTE ENDP

; 自动演奏
AUTO_PLAY PROC
    MOV CX, NOTE_COUNT   ; 获取音符数量
    MOV SI, OFFSET MUSIC_NOTES
    MOV DI, OFFSET MUSIC_DELAY

AUTO_PLAY_LOOP:
    MOV AL, [SI]         ; 加载当前音符
    CALL MAP_KEY_TO_FREQ
    CALL PLAY_NOTE

    INC SI               ; 指向下一个音符
    INC DI               ; 指向下一个延时时间
    LOOP AUTO_PLAY_LOOP
    RET
AUTO_PLAY ENDP

; 切换高音
SHIFT_HIGH PROC
    MOV AX, OFFSET FREQ_TABLE_HIGH
    MOV CURRENT_TABLE, AX
    RET
SHIFT_HIGH ENDP

; 切换低音
SHIFT_LOW PROC
    MOV AX, OFFSET FREQ_TABLE_LOW
    MOV CURRENT_TABLE, AX
    RET
SHIFT_LOW ENDP

; 延时子程序
DELAY PROC
    MOV CX, 0FFFFH       ; 设置延时循环
DELAY_LOOP:
    LOOP DELAY_LOOP
    RET
DELAY ENDP

CODE ENDS
END START
