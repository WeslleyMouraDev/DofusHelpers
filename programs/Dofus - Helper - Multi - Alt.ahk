#Requires AutoHotkey v2.0
SendMode "Input"

; ---------------------------
; Configurações
; ---------------------------
global dofusExe := "Dofus.exe"
global followKey := "End"
global windowsDofus := []
global currentIndex := 1
global leaderHwnd := ""

; Variáveis HUD
global hud := ""
global hudText := ""
global leaderText := ""
global currentText := ""
global pulseStep := 5
global hudVisible := true
global pulseDir := 1
global pulseVal := 100

; Variáveis para a fila de cliques
global clickQueue := []

; Variáveis Nidas GUI
global nidasGui := ""
global nidasVisible := false

; Cores para elementos Nidas
global ColorForca := 0x8B4513    ; Marrom
global ColorInt := 0xFF0000      ; Vermelho
global ColorAgi := 0x008000      ; Verde
global ColorSorte := 0x68b2f8    ; Azul

; ---------------------------
; Criação do HUD
; ---------------------------
CreateHUD() {
    global hud, hudText, leaderText, currentText
    ; Cria um HUD sem borda/título (-Caption) e sempre no topo
    hud := Gui("+AlwaysOnTop -Caption +ToolWindow")
    hud.BackColor := "000000" ; Cor de fundo que será transparente
    hud.SetFont("s10", "Segoe UI") ; Fonte mais moderna
    hudText := hud.Add("Text", "x10 y8 w220 cFFFFFF vHudMain", "")
    currentText := hud.Add("Text", "x10 y25 w220 c0099FF vCurrent", "") ; Texto azul para a janela atual
    leaderText := hud.Add("Text", "x10 y45 w220 c00FF00 vLeader", "")

    ; Botão de ajuda para listar os atalhos
    helpBtn := hud.Add("Button", "x210 y8 w20 h20", "+")
    helpBtn.Visible := false ; Começa invisível
    helpBtn.OnEvent("Click", (*) => ShowHelp())
        
    hud.Show("x10 y10 w240 h70 NA")
    WinSetTransparent(180, hud) ; Define a transparência (0-255)
    OnMessage(0x201, MoveHUD_WM) ; WM_LBUTTONDOWN
    OnMessage(0x200, TrackMouseOnHUD) ; WM_MOUSEMOVE
    OnMessage(0x2A3, TrackMouseOnHUD) ; WM_MOUSELEAVE
    SetTimer(UpdateHUD, 100)
    SetTimer(ProcessClickQueue, 20) ; Inicia o processador da fila de cliques
}

TrackMouseOnHUD(wParam, lParam, msg, hwnd) {
    global hud
    static isMouseOverButton := false

    if (hwnd = hud.Hwnd) {
        helpBtn := hud["+"] ; Acessa o botão pelo seu texto
        helpBtn.GetPos(&btnX, &btnY, &btnW, &btnH)
        x := lParam & 0xFFFF
        y := lParam >> 16

        isOver := (msg != 0x2A3) && (x >= btnX && x <= btnX + btnW && y >= btnY && y <= btnY + btnH)
        helpBtn.Visible := isOver
    }
}

; ---------------------------
; Atualização do HUD + Pulse
; ---------------------------
UpdateHUD() {
    global windowsDofus, currentIndex, leaderHwnd, hud, hudText, leaderText, currentText, hudVisible

    if (!hudVisible) {
        Return
    }

    hud.Show("NA")

    captured := windowsDofus.Length
    leaderName := ""
    currentName := ""

    if (leaderHwnd != "") {
        leaderName := GetCharacterName(leaderHwnd)
    } 

    if (windowsDofus.Length >= currentIndex) {
        currentName := GetCharacterName(windowsDofus[currentIndex])
    }

    hudText.Text := "Janelas: " . captured
    currentText.Text := "Atual: " . currentIndex . " - " . currentName

    if (leaderName != "") {
        leaderText.Text := "Líder: " . leaderName 
    } else {
        leaderText.Text := "Líder: Nenhum"
    }

    ; Destaca o líder com negrito em vez de piscar
    if (windowsDofus.Length >= currentIndex && windowsDofus[currentIndex] = leaderHwnd) {
        leaderText.SetFont("s10 Bold")
    } else {
        leaderText.SetFont("s10")
    }
}

; ---------------------------
; Funções principais
; ---------------------------
GetCharacterName(hwnd) {
    if !WinExist("ahk_id " . hwnd) {
        Return ""
    }
    fullTitle := WinGetTitle(hwnd)
    ; O título é "NomePersonagem - Dofus...". Pegamos a primeira parte.
    parts := StrSplit(fullTitle, " - ")
    Return parts.Length > 0 ? Trim(parts[1]) : fullTitle
}

MoveHUD_WM(wParam, lParam, msg, hwnd) {
    global hud
    ; Se a mensagem for para a janela do HUD, inicia o arraste.
    if (hwnd = hud.Hwnd) {
        PostMessage(0xA1, 2, 0) ; WM_NCLBUTTONDOWN, HTCAPTION
    }
}

UpdateWindows(playSound := true) {
    global windowsDofus, currentIndex, dofusExe

    list := []
    ; Itera apenas nas janelas do Dofus que têm um título, para mais eficiência
    for hwnd in WinGetList("ahk_exe " . dofusExe) {
        if (WinGetTitle(hwnd) != "") {
            list.Push(hwnd)
        }
    }

    windowsDofus := list

    if (currentIndex > windowsDofus.Length) {
        currentIndex := windowsDofus.Length > 0 ? 1 : 0
    }
    if (currentIndex = 0 && windowsDofus.Length > 0) {
        currentIndex := 1
    }
    if (playSound) {
        SoundBeep(750, 150) ; Beep de confirmação para janelas atualizadas
    }
    UpdateHUD()
}

SwitchWindow(next := true) {
    ; Garante que a função não seja interrompida e que apenas uma instância
    ; seja executada por vez, prevenindo "pulos" de janelas.
    Critical

    global windowsDofus, currentIndex
    if (windowsDofus.Length = 0) {
        Return
    }

    if (next) {
        currentIndex := Mod(currentIndex, windowsDofus.Length) + 1
    } else {
        currentIndex--
        if (currentIndex < 1) {
            currentIndex := windowsDofus.Length
        }
    }

    ; Ativa a janela apenas se ela ainda existir
    if WinExist("ahk_id " . windowsDofus[currentIndex]) {
        targetHwnd := windowsDofus[currentIndex]
        WinActivate(targetHwnd)
        ; Espera a janela alvo se tornar ativa antes de permitir a próxima troca.
        WinWaitActive("ahk_id " . targetHwnd, , 0.5)
    }

    ; Força a atualização do HUD para refletir a nova janela ativa imediatamente.
    UpdateHUD()
}

SetLeader() {
    global leaderHwnd, currentIndex, windowsDofus
    if (windowsDofus.Length = 0) {
        Return
    }
    leaderHwnd := windowsDofus[currentIndex]
    SoundBeep(1000, 150) ; Beep de confirmação para líder definido
    UpdateHUD()
}

FollowAll() {
    global leaderHwnd, followKey, windowsDofus
    if (windowsDofus.Length = 0 || leaderHwnd = "") {
        Return
    }

    for hwnd in windowsDofus {
        ; Garante que a janela ainda existe e não é o líder
        if (hwnd != leaderHwnd && WinExist("ahk_id " . hwnd)) {
            WinActivateBottom(hwnd)
            Sleep(50)
            Send("{" . followKey . "}")
            Sleep(50)
        }
    }

    WinActivate(leaderHwnd)
}

ProcessClickQueue() {
    static isProcessing := false
    global clickQueue, windowsDofus

    ; Impede a reentrada se um clique já estiver sendo processado ou se a fila estiver vazia
    if (isProcessing || clickQueue.Length = 0) {
        Return
    }

    isProcessing := true
    Critical ; Impede que a função seja interrompida durante o processamento

    ; Pega o próximo clique da fila
    clickData := clickQueue.RemoveAt(1)
    mx := clickData.x
    my := clickData.y

    if (windowsDofus.Length > 0) {
        SetControlDelay(-1)
        for hwnd in windowsDofus {
            if WinExist("ahk_id " . hwnd) {
                WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " . hwnd)
                cx := mx - wx
                cy := my - wy
                lParam := (cy << 16) | (cx & 0xFFFF)
                PostMessage(0x201, 1, lParam, , "ahk_id " . hwnd) ; WM_LBUTTONDOWN
                PostMessage(0x202, 0, lParam, , "ahk_id " . hwnd) ; WM_LBUTTONUP
            }
        }
    }

    isProcessing := false
}

; ---------------------------
; Funções GUI Nidas
; ---------------------------
CreateNidasGui() {
    global nidasGui, ColorForca, ColorAgi, ColorSorte, ColorInt
    
    ; Criar GUI transparente sem bordas e sem título
    nidasGui := Gui("+AlwaysOnTop +ToolWindow -Caption -MaximizeBox -MinimizeBox", "Dicas Nidas")
    nidasGui.BackColor := "000000"  ; Fundo preto
    nidasGui.SetFont("s9", "Segoe UI")
    
    ; Informações dos mobs
    yPos := 10
    
    ; Rei Nidas
    nidasGui.Add("Text", "x10 y" . yPos . " w200 h15 c0xFFFFFF", "Rei Nidas:")
    yPos += 15
    nidasGui.Add("Text", "x20 y" . yPos . " w30 h15 c" . Format("0x{:X}", ColorAgi), "Agi")
    nidasGui.Add("Text", "x50 y" . yPos . " w10 h15 c0xFFFFFF", ">")
    nidasGui.Add("Text", "x65 y" . yPos . " w30 h15 c" . Format("0x{:X}", ColorSorte), "Sor")
    yPos += 20
    
    ; Kamasterisko
    nidasGui.Add("Text", "x10 y" . yPos . " w200 h15 c0xFFFFFF", "Kamasterisko:")
    yPos += 15
    nidasGui.Add("Text", "x20 y" . yPos . " w30 h15 c" . Format("0x{:X}", ColorSorte), "Sor")
    nidasGui.Add("Text", "x50 y" . yPos . " w10 h15 c0xFFFFFF", ">")
    nidasGui.Add("Text", "x65 y" . yPos . " w30 h15 c" . Format("0x{:X}", ColorAgi), "Agi")
    yPos += 20
    
    ; Barbastrela
    nidasGui.Add("Text", "x10 y" . yPos . " w200 h15 c0xFFFFFF", "Barbastrela:")
    yPos += 15
    nidasGui.Add("Text", "x20 y" . yPos . " w25 h15 c" . Format("0x{:X}", ColorInt), "Int")
    nidasGui.Add("Text", "x45 y" . yPos . " w10 h15 c0xFFFFFF", ">")
    nidasGui.Add("Text", "x60 y" . yPos . " w25 h15 c" . Format("0x{:X}", ColorSorte), "Sor")
    nidasGui.Add("Text", "x85 y" . yPos . " w10 h15 c0xFFFFFF", ">")
    nidasGui.Add("Text", "x100 y" . yPos . " w25 h15 c" . Format("0x{:X}", ColorAgi), "Agi")
    yPos += 20
    
    ; Levitrof
    nidasGui.Add("Text", "x10 y" . yPos . " w200 h15 c0xFFFFFF", "Levitrof:")
    yPos += 15
    nidasGui.Add("Text", "x20 y" . yPos . " w25 h15 c" . Format("0x{:X}", ColorForca), "For")
    nidasGui.Add("Text", "x45 y" . yPos . " w10 h15 c0xFFFFFF", ">")
    nidasGui.Add("Text", "x60 y" . yPos . " w25 h15 c" . Format("0x{:X}", ColorInt), "Int")
    nidasGui.Add("Text", "x85 y" . yPos . " w10 h15 c0xFFFFFF", ">")
    nidasGui.Add("Text", "x100 y" . yPos . " w25 h15 c" . Format("0x{:X}", ColorSorte), "Sor")
    nidasGui.Add("Text", "x125 y" . yPos . " w10 h15 c0xFFFFFF", ">")
    nidasGui.Add("Text", "x140 y" . yPos . " w25 h15 c" . Format("0x{:X}", ColorAgi), "Agi")
    yPos += 20
    
    ; Xavero
    nidasGui.Add("Text", "x10 y" . yPos . " w200 h15 c0xFFFFFF", "Xavero:")
    yPos += 15
    nidasGui.Add("Text", "x20 y" . yPos . " w25 h15 c" . Format("0x{:X}", ColorForca), "For")
    nidasGui.Add("Text", "x45 y" . yPos . " w10 h15 c0xFFFFFF", ">")
    nidasGui.Add("Text", "x60 y" . yPos . " w25 h15 c" . Format("0x{:X}", ColorInt), "Int")
    nidasGui.Add("Text", "x85 y" . yPos . " w10 h15 c0xFFFFFF", ">")
    nidasGui.Add("Text", "x100 y" . yPos . " w25 h15 c" . Format("0x{:X}", ColorAgi), "Agi")
    yPos += 20
    
    ; Pelutrof
    nidasGui.Add("Text", "x10 y" . yPos . " w200 h15 c0xFFFFFF", "Pelutrof:")
    yPos += 15
    nidasGui.Add("Text", "x20 y" . yPos . " w25 h15 c" . Format("0x{:X}", ColorAgi), "Agi")
    nidasGui.Add("Text", "x45 y" . yPos . " w10 h15 c0xFFFFFF", ">")
    nidasGui.Add("Text", "x65 y" . yPos . " w25 h15 c" . Format("0x{:X}", ColorForca), "For")
    
    ; Tornar a janela móvel
    nidasGui.OnEvent("Close", (*) => ToggleNidasGui())
    OnMessage(0x201, MoveNidas_WM)
    
    ; Configurar transparência
    WinSetTransparent(220, nidasGui)
}

ToggleNidasGui() {
    global nidasGui, nidasVisible
    
    if (!nidasGui) {
        CreateNidasGui()
    }
    
    if (nidasVisible) {
        nidasGui.Hide()
        nidasVisible := false
    } else {
        nidasGui.Show("w180 h220")
        nidasVisible := true
    }
}

MoveNidas_WM(wParam, lParam, msg, hwnd) {
    global nidasGui
    ; Se a mensagem for para a janela do Nidas, inicia o arraste.
    if (nidasGui && hwnd = nidasGui.Hwnd) {
        PostMessage(0xA1, 2, 0) ; WM_NCLBUTTONDOWN, HTCAPTION
    }
}

; ---------------------------
; Funções auxiliares para hotkeys
; ---------------------------
NextWindowFunc() {
    SwitchWindow(true)
    ; Usar timer para KeyWait evita problemas
    SetTimer(() => KeyWait("Right"), -10)
}

PrevWindowFunc() {
    SwitchWindow(false)
    SetTimer(() => KeyWait("Left"), -10)
}

UpdateWindowsFunc(*) {
    UpdateWindows(true)
}

FollowAllFunc(*) {
    FollowAll()
}

SetLeaderFunc(*) {
    SetLeader()
}

MultiClickFunc(*) {
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mx, &my)
    clickQueue.Push({x: mx, y: my})
}

NidasToggleFunc(*) {
    ToggleNidasGui()
}

ToggleHUD(*) {
    global hud, hudVisible
    if (hudVisible) {
        hud.Hide()
    } else {
        hud.Show("NA") ; Usa "NA" para não ativar a janela
    }
    hudVisible := !hudVisible
}

ShowHelp(*) {
    helpText := "
    (
    LISTA DE ATALHOS

    `Seta Direita` : Próxima Janela
    - Alterna para a próxima janela do Dofus na lista.

    `Seta Esquerda` : Janela Anterior
    - Alterna para a janela anterior do Dofus na lista.

    `F2` : Ir para o Líder
    - Foca diretamente na janela do personagem líder.

    `Home` : Definir Líder
    - Define a janela atual como o personagem líder.

    `PgDn` : Seguir Todos
    - Faz todos os outros personagens seguirem o líder.

    `Alt + 1` : Multi Click
    - Envia um clique do mouse para todas as janelas abertas.

    `PgUp` : Atualizar Janelas
    - Procura novamente por janelas do Dofus abertas.

    `Ctrl + Q` : Dicas Nidas
    - Mostra/oculta a janela de dicas para a dungeon Nidas.
    )"
    
    MsgBox(helpText, "Guia de Atalhos", "OK")
}

SwitchToLeaderFunc(*) {
    global leaderHwnd, windowsDofus, currentIndex

    if (leaderHwnd = "" || !WinExist("ahk_id " . leaderHwnd)) {
        SoundBeep(400, 150) ; Beep de erro se não houver líder
        Return
    }

    ; Encontra o índice do líder no array
    leaderIndex := 0
    for i, hwnd in windowsDofus {
        if (hwnd = leaderHwnd) {
            leaderIndex := i
            break
        }
    }

    if (leaderIndex > 0) {
        currentIndex := leaderIndex
        ; Ativa a janela do líder diretamente, sem decrementar o índice
        WinActivate("ahk_id " . leaderHwnd)
        WinWaitActive("ahk_id " . leaderHwnd, , 0.5)
        UpdateHUD()
    }
}

; ---------------------------
; Hotkeys (Fixos)
; ---------------------------
z::NextWindowFunc()
\::PrevWindowFunc()
PgUp::UpdateWindowsFunc()
PgDn::FollowAllFunc()
Home::SetLeaderFunc()
!1::MultiClickFunc()
^q::NidasToggleFunc()
F2::SwitchToLeaderFunc()
!m::ToggleHUD()

; ---------------------------
; Inicialização
; ---------------------------
CreateHUD()
UpdateWindows(false) ; Captura as janelas ao iniciar o script, sem som

; ================================
; Configurações globais para máxima performance
; ================================
A_BatchLines := -1
SetKeyDelay(-1, -1)
SetMouseDelay(-1)
SetWinDelay(-1)
A_CoordModeMouse := "Screen"
